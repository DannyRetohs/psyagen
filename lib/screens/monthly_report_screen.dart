import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agenda_provider.dart';
import '../widgets/glass_container.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final Color darkTeal = const Color(0xFF1D3038);
  final Color sandPeach = const Color(0xFF315A68);

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();

    // 1. Filtrar citas del mes seleccionado
    final filteredAppts = provider.appointments.where((a) {
      return a.scheduledDate.year == _selectedYear &&
             a.scheduledDate.month == _selectedMonth;
    }).toList();

    // 2. Clasificar las programadas y las realizadas
    final scheduledCount = filteredAppts.length;
    final attendedAppts = filteredAppts.where((a) => a.status.contains('Llegó')).toList();
    final realizedCount = attendedAppts.length;

    // 3. NNA Atendidos (Pacientes únicos con citas realizadas en ese mes)
    final uniquePatientIds = attendedAppts.map((a) => a.patientId).toSet();
    final totalNNA = uniquePatientIds.length;

    // 4. Desglose de Género y Edad basado en los pacientes únicos
    int mujeres = 0;
    int hombres = 0;
    int age5to11 = 0;
    int age12to17 = 0;

    for (var pid in uniquePatientIds) {
      final p = provider.getPatientById(pid);
      if (p != null) {
        if (p.gender == 'Femenino') mujeres++;
        if (p.gender == 'Masculino') hombres++;

        if (p.age >= 5 && p.age <= 11) {
          age5to11++;
        } else if (p.age >= 12 && p.age <= 17) {
          age12to17++;
        }
      }
    }

    // 5. Agrupación por Día
    final Map<int, Map<String, int>> dailyStats = {};
    for (var appt in filteredAppts) {
      final day = appt.scheduledDate.day;
      dailyStats.putIfAbsent(day, () => {
        'programadas': 0,
        'realizadas': 0,
        'mujeres': 0,
        'hombres': 0,
      });

      dailyStats[day]!['programadas'] = dailyStats[day]!['programadas']! + 1;

      if (appt.status.contains('Llegó')) {
        dailyStats[day]!['realizadas'] = dailyStats[day]!['realizadas']! + 1;
        final p = provider.getPatientById(appt.patientId);
        if (p != null) {
          if (p.gender == 'Femenino') dailyStats[day]!['mujeres'] = dailyStats[day]!['mujeres']! + 1;
          if (p.gender == 'Masculino') dailyStats[day]!['hombres'] = dailyStats[day]!['hombres']! + 1;
        }
      }
    }
    final int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;

    // Texto Institucional
    final monthName = _months[_selectedMonth - 1];
    final isCurrentYear = _selectedYear == DateTime.now().year;
    final yearStr = isCurrentYear ? 'de la presente anualidad' : 'del año $_selectedYear';
    final reportText = 'Durante el mes de $monthName $yearStr se atendieron a $totalNNA NNA mediante atención psicológica.';

    // Opciones de Año
    final List<int> years = List.generate(5, (index) => DateTime.now().year - 2 + index);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Reporte Mensual', style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Controles para seleccionar mes y año
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down, color: darkTeal),
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(_months[index], style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold)),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMonth = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down, color: darkTeal),
                          items: years.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text('$y', style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedYear = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bloque del texto institucional
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Icon(Icons.assignment_turned_in, color: sandPeach, size: 40),
                    // const SizedBox(height: 16),
                    Text(
                      reportText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Estadísticas Generales de Citas
              Text('Citas del Mes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: darkTeal)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statCard('Programadas', scheduledCount.toString(), Colors.blueAccent, Icons.calendar_today)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Realizadas', realizedCount.toString(), sandPeach, Icons.check_circle_outline)),
                ],
              ),
              const SizedBox(height: 24),

              // Desglose de NNA
              Text('Desglose de Población ($totalNNA NNA)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: darkTeal)),
              const SizedBox(height: 12),
              
              // Género
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: sandPeach),
                        const SizedBox(width: 8),
                        Text('Por Género', style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoBlock('Mujeres', mujeres.toString(), const Color(0xFFE8BD8A)),
                        _infoBlock('Hombres', hombres.toString(), Colors.blueAccent.shade100),
                        _infoBlock('Total', totalNNA.toString(), darkTeal),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Edad
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cake, color: sandPeach),
                        const SizedBox(width: 8),
                        Text('Rango de Edades', style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoBlock('5 - 11 años', age5to11.toString(), sandPeach),
                        _infoBlock('12 - 17 años', age12to17.toString(), sandPeach.withOpacity(0.8)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Desglose Diario en Tabla
              Text('Actividad Diaria Completa', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: darkTeal)),
              const SizedBox(height: 12),
              _buildActivityTable(daysInMonth, dailyStats),

              const SizedBox(height: 80), // Espacio para el bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String count, Color iconColor, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: darkTeal)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: darkTeal.withOpacity(0.7), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: darkTeal.withOpacity(0.7), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActivityTable(int daysInMonth, Map<int, Map<String, int>> dailyStats) {
    int sumProg = 0;
    int sumReal = 0;
    int sumMujeres = 0;
    int sumHombres = 0;

    List<DataRow> rows = [];
    for (int day = 1; day <= daysInMonth; day++) {
       final stats = dailyStats[day] ?? {'programadas': 0, 'realizadas': 0, 'mujeres': 0, 'hombres': 0};
       final prog = stats['programadas']!;
       final real = stats['realizadas']!;
       final mujeres = stats['mujeres']!;
       final hombres = stats['hombres']!;

       sumProg += prog;
       sumReal += real;
       sumMujeres += mujeres;
       sumHombres += hombres;

       rows.add(DataRow(cells: [
         DataCell(Text(day.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal))),
         DataCell(Text(prog.toString(), style: TextStyle(color: darkTeal))),
         DataCell(Text(real.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: sandPeach))),
         DataCell(Text(mujeres.toString(), style: TextStyle(color: const Color(0xFFE8BD8A)))),
         DataCell(Text(hombres.toString(), style: TextStyle(color: Colors.blueAccent))),
         DataCell(Text(real.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal))),
       ]));
    }

    // Fila de Totales
    rows.add(DataRow(
      cells: [
         DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 16))),
         DataCell(Text(sumProg.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 16))),
         DataCell(Text(sumReal.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 16))),
         DataCell(Text(sumMujeres.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 16))),
         DataCell(Text(sumHombres.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 16))),
         DataCell(Text(sumReal.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 16))),
      ]
    ));

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: darkTeal),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Día')),
            DataColumn(label: Text('Prog.')),
            DataColumn(label: Text('Reales')),
            DataColumn(label: Text('Mujeres')),
            DataColumn(label: Text('Hombres')),
            DataColumn(label: Text('Total')),
          ],
          rows: rows,
        ),
      ),
    );
  }
}
