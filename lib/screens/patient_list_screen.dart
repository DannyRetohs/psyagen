import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agenda_provider.dart';
import '../widgets/glass_container.dart';
import 'patient_form_screen.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  String _searchQuery = '';
  final Color deepPurple = const Color(0xFF4A148C);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();
    final allPatients = provider.patients;
    
    final filteredPatients = allPatients.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Background transparent for liquid
      appBar: AppBar(
        title: Text('Directorio de Pacientes', style: TextStyle(fontWeight: FontWeight.bold, color: deepPurple)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              style: TextStyle(color: deepPurple),
              decoration: InputDecoration(
                hintText: 'Buscar paciente...',
                hintStyle: TextStyle(color: deepPurple.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: deepPurple),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredPatients.isEmpty
                ? Center(child: Text('No hay pacientes que coincidan.', style: TextStyle(color: deepPurple.withOpacity(0.7))))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final p = filteredPatients[index];
                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: p.isActive 
                                  ? const Color(0xFFCE93D8).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.5),
                                child: Text(p.name.substring(0, 1).toUpperCase(), 
                                  style: TextStyle(
                                    color: p.isActive ? const Color(0xFFCE93D8) : deepPurple.withOpacity(0.5), 
                                    fontWeight: FontWeight.bold, fontSize: 18)
                                ),
                              ),
                              if (!p.isActive)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(p.name, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16,
                                    decoration: p.isActive ? null : TextDecoration.lineThrough,
                                    color: p.isActive ? deepPurple : deepPurple.withOpacity(0.5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!p.isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Baja', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('${p.age} años • ${p.generalReason}', style: TextStyle(color: deepPurple.withOpacity(0.7))),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: deepPurple.withOpacity(0.4)),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PatientDetailScreen(patientId: p.id)
                            ));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'patient_list_fab',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientFormScreen()));
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
