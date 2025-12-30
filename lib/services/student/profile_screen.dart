import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uni_escom/services/notifications/bloc/notifications_bloc.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();

  String _rol = '';
  String _seccionOrg = '';
  String? _fotoUrl;      // url actual (Firestore)
  File? _fotoFile;       // foto seleccionada local
  bool _uploadingPhoto = false;
  String _fotoOriginal = '';

  final _nombreController = TextEditingController();

  List<String> misIntereses = [];
  final List<String> opcionesIntereses = const ['Académico', 'Cultural', 'Deportivo'];

  bool _loading = true;
  bool _saving = false;

  String _nombreOriginal = '';
  List<String> _interesesOriginal = [];

  bool notifEnabled = true;
  bool notifRecordatorios = true;
  bool notifAvisarOrganizador = true;
  bool notifCambiosEvento = true;

  Map<String, dynamic> _prefsOriginal = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  // ---------- CARGA ----------
  Future<void> _cargarDatos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
  
      final doc =
          await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (!mounted) return;
  
      final data = doc.data() ?? {};
      final rol = (data['rol'] ?? 'estudiante').toString();
      final seccion = (data['seccion_org'] ?? '').toString();

  
      final nombre = (data['nombre'] ?? '').toString();
      final intereses = List<String>.from(data['intereses'] ?? []);
  
      final fotoUrl = (data['fotoUrl'] ?? '').toString(); // ✅ AQUÍ
  
      final notifs = Map<String, dynamic>.from(data['notificaciones'] ?? {});
      final enabled = (notifs['enabled'] ?? true) == true;
      final rec = (notifs['recordatorios_eventos'] ?? true) == true;
      final org = (notifs['avisar_organizador'] ?? true) == true;
      final cambios = (notifs['cambios_evento'] ?? true) == true;
  
      setState(() {
        _fotoUrl = fotoUrl.isEmpty ? null : fotoUrl;
        _fotoOriginal = fotoUrl;

        _rol = rol;
        _seccionOrg = seccion;

        _nombreController.text = nombre;
        misIntereses = intereses;
  
        _nombreOriginal = nombre;
        _interesesOriginal = List<String>.from(intereses);
  
        notifEnabled = enabled;
        notifRecordatorios = rec;
        notifAvisarOrganizador = org;
        notifCambiosEvento = cambios;
  
        _prefsOriginal = {
          'enabled': enabled,
          'recordatorios_eventos': rec,
          'avisar_organizador': org,
          'cambios_evento': cambios,
        };

  
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo cargar el perfil"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _prettySeccion(String s) {
          switch (s) {
            case 'sec_academica': return 'Sección Académica';
            case 'sec_cultural': return 'Sección Cultural';
            case 'sec_deportiva': return 'Sección Deportiva';
            case 'sec_administrativa': return 'Sección Administrativa (todas)';
            default: return 'Sin sección asignada';
          }
  }

  //para elegir imagen de perfil
  Future<void> _pickFoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (xfile == null) return;

    setState(() {
      _fotoFile = File(xfile.path);
    });
  }


  Future<String?> _subirFotoPerfil(String uid) async {
    if (_fotoFile == null) return null;

    final ref = FirebaseStorage.instance.ref().child('profile_photos/$uid.jpg');

    await ref.putFile(
      _fotoFile!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await ref.getDownloadURL();
  }



  // ---------- CAMBIOS ----------
  bool get _hayCambiosNotifs {
    return notifEnabled != (_prefsOriginal['enabled'] ?? true) ||
        notifRecordatorios != (_prefsOriginal['recordatorios_eventos'] ?? true) ||
        notifAvisarOrganizador != (_prefsOriginal['avisar_organizador'] ?? true) ||
        notifCambiosEvento != (_prefsOriginal['cambios_evento'] ?? true);
        
  }

  bool get _hayCambios {
    final nombre = _nombreController.text.trim();
    if (nombre != _nombreOriginal.trim()) return true;

    final a = [...misIntereses]..sort();
    final b = [..._interesesOriginal]..sort();
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    if (_fotoFile != null) return true; // si escogió una nueva foto
    return false;
  }

  // ---------- GUARDAR PREFS (SIN SNACKBAR AQUÍ) ----------
  void _guardarPreferenciasNotifs() {
    final prefs = {
      'enabled': notifEnabled,
      'recordatorios_eventos': notifRecordatorios,
      'avisar_organizador': notifAvisarOrganizador,
      'cambios_evento': notifCambiosEvento,
    };
    context.read<NotificationsBloc>().add(NotificationsUpdatePrefs(prefs));
  }

  // ---------- GUARDAR PERFIL ----------
  Future<void> _actualizarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre no puede estar vacío")),
      );
      return;
    }

   setState(() => _saving = true);

  try {
      String? nuevaUrl;

      // 1) Si el usuario eligió foto nueva, la subimos primero
      if (_fotoFile != null) {
        setState(() => _uploadingPhoto = true);
        nuevaUrl = await _subirFotoPerfil(user.uid);
        setState(() => _uploadingPhoto = false);
      }

      // 2) Armamos el update
      final updateData = <String, dynamic>{
        'nombre': nombre,
        'intereses': misIntereses,
      };

      if (nuevaUrl != null) {
        updateData['fotoUrl'] = nuevaUrl;
      }

      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update(updateData);

      if (!mounted) return;

      setState(() {
        _nombreOriginal = nombre;
        _interesesOriginal = List<String>.from(misIntereses);

        if (nuevaUrl != null) {
          _fotoUrl = nuevaUrl;
          _fotoOriginal = nuevaUrl;
        }

        _fotoFile = null; // ya se subió
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado"), backgroundColor: Colors.green),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo actualizar el perfil"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }

  }

  String _initialFromName(String name) {
    final t = name.trim();
    if (t.isEmpty) return "U";
    return t.characters.first.toUpperCase();
  }

  // ---------- FEEDBACK (SNACKBARS) ----------
  void _showSnack(String text, {required bool ok}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<NotificationsBloc, NotificationsState>(
      listener: (context, state) {
        // Permisos
        if (state is NotificationsPermissionGranted) {
          _showSnack("Permiso de notificaciones concedido ✅", ok: true);
        } else if (state is NotificationsPermissionDenied) {
          _showSnack("Permiso de notificaciones denegado ❌", ok: false);
        }

        // Token guardado
        if (state is NotificationsTokenReceived) {
          _showSnack("Token FCM guardado en Firebase ✅", ok: true);
        }

        // Prefs guardadas
        if (state is NotificationsPrefsUpdated) {
          // actualiza tu copia local de originales (para que el botón se desactive)
          setState(() {
            _prefsOriginal = Map<String, dynamic>.from(state.prefs);
          });
          _showSnack("Preferencias guardadas ✅", ok: true);
        }

        // Si quieres mostrar algo también cuando llega un mensaje
        if (state is NotificationsForegroundMessage) {
           final t = state.message.notification?.title ?? state.message.data['title'] ?? "UniEscom";
           final b = state.message.notification?.body ?? state.message.data['body'] ?? "";
           _showSnack("$t: $b", ok: true); // o quítalo si ya te molesta
         }

        // Error
        if (state is NotificationsError) {
          _showSnack(state.message, ok: false);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Mi Perfil")),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, notifState) {
                  final notifBusy = notifState is NotificationsLoading;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header
                        Card(
                          elevation: 10,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: cs.primary.withOpacity(0.12),
                                      backgroundImage: _fotoFile != null
                                          ? FileImage(_fotoFile!)
                                          : (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                                              ? NetworkImage(_fotoUrl!)
                                              : null,
                                      child: (_fotoFile == null && (_fotoUrl == null || _fotoUrl!.isEmpty))
                                          ? Text(
                                              _initialFromName(_nombreController.text),
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: cs.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Tu perfil",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Edita tu nombre e intereses",
                                            style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _uploadingPhoto ? null : _pickFoto,
                                    icon: _uploadingPhoto
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.photo_camera),
                                    label: Text(_uploadingPhoto ? "SUBIENDO..." : "CAMBIAR FOTO"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      

                        const SizedBox(height: 14),

                        // Nombre
                        Card(
                          elevation: 6,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Nombre", style: TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _nombreController,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    hintText: "Ej. Rata Ratón Ramirez",
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ),

                        //Cuenta
                        const SizedBox(height: 14),
                        Card(
                          elevation: 6,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Cuenta", style: TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined),
                                    const SizedBox(width: 10),
                                    Text("Rol: $_rol"),
                                  ],
                                ),
                                
                               if (_rol == 'organizador' || _rol == 'admin') ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.apartment_outlined),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text("Sección: ${_prettySeccion(_seccionOrg)}")),
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Intereses
                        Card(
                          elevation: 6,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Mis intereses", style: TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 8),
                                Text(
                                  "Selecciona lo que te interesa para personalizar eventos.",
                                  style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: opcionesIntereses.map((interes) {
                                    final selected = misIntereses.contains(interes);
                                    return FilterChip(
                                      label: Text(interes),
                                      selected: selected,
                                      selectedColor: cs.primary.withOpacity(0.18),
                                      checkmarkColor: cs.primary,
                                      onSelected: (val) {
                                        setState(() {
                                          if (val) {
                                            if (!misIntereses.contains(interes)) misIntereses.add(interes);
                                          } else {
                                            misIntereses.remove(interes);
                                          }
                                        });
                                      },
                                      labelStyle: TextStyle(
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                        color: selected ? cs.primary : cs.onSurface.withOpacity(0.75),
                                      ),
                                      side: BorderSide(color: Colors.black.withOpacity(0.10)),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Notificaciones
                        Card(
                          elevation: 6,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Notificaciones", style: TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 8),
                                Text(
                                  "Configura tus preferencias (RF-017).",
                                  style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                                ),
                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: notifBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.notifications_active_outlined),
                                    label: const Text("PERMITIR NOTIFICACIONES"),
                                    onPressed: notifBusy
                                        ? null
                                        : () {
                                            context
                                                .read<NotificationsBloc>()
                                                .add(const NotificationsRequestPermission());
                                          },
                                  ),
                                ),

                                const SizedBox(height: 10),

                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("Activar notificaciones"),
                                  value: notifEnabled,
                                  onChanged: (v) => setState(() => notifEnabled = v),
                                ),

                                const Divider(height: 1),

                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("Recordatorios de eventos próximos (RF-015)"),
                                  value: notifRecordatorios,
                                  onChanged: notifEnabled ? (v) => setState(() => notifRecordatorios = v) : null,
                                ),

                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("Notificar al organizador si me registro (RF-016)"),
                                  value: notifAvisarOrganizador,
                                  onChanged:
                                      notifEnabled ? (v) => setState(() => notifAvisarOrganizador = v) : null,
                                ),

                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("Cambios en eventos registrados (RF-017)"),
                                  value: notifCambiosEvento,
                                  onChanged: notifEnabled ? (v) => setState(() => notifCambiosEvento = v) : null,
                                ),

                                const SizedBox(height: 8),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: (_hayCambiosNotifs && !notifBusy) ? _guardarPreferenciasNotifs : null,
                                    child: Text(notifBusy ? "GUARDANDO..." : "GUARDAR PREFERENCIAS"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Guardar perfil
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (!_hayCambios || _saving) ? null : _actualizarPerfil,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _saving
                                  ? const SizedBox(
                                      key: ValueKey("saving"),
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("GUARDAR CAMBIOS", key: ValueKey("text")),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
