import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/agenda_provider.dart';
import '../widgets/glass_container.dart';
import 'patient_list_screen.dart';
import 'appointment_form_screen.dart';
import 'appointment_detail_screen.dart';
import 'event_form_screen.dart';
import 'psychoeducation_form_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final Color darkTeal = const Color(0xFF1D3038);

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgendaProvider>();

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: darkTeal)),
      );
    }

    // Filtramos las citas por _selectedDay
    final dayAppointments = provider.appointments.where((a) {
      return a.scheduledDate.year == _selectedDay.year &&
          a.scheduledDate.month == _selectedDay.month &&
          a.scheduledDate.day == _selectedDay.day;
    }).toList();

    dayAppointments.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    // Filtramos los eventos del profesional
    final dayEvents = provider.events.where((e) {
      return e.date.year == _selectedDay.year &&
          e.date.month == _selectedDay.month &&
          e.date.day == _selectedDay.day;
    }).toList();
    dayEvents.sort((a, b) => a.date.compareTo(b.date));

    final bool isAbsent = dayEvents.any((e) => e.type == 'Inasistencia');

    final int totalDay = dayAppointments.length;
    final int attendedDay = dayAppointments
        .where((a) => a.status.contains('Llegó'))
        .length;
    final int missedDay = dayAppointments
        .where((a) => a.status == 'No llegó')
        .length;
    final int pendingDay = dayAppointments
        .where((a) => a.status == 'Programada')
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent, // Dejar ver el LiquidBackground

      // appBar: AppBar(
      //   title: Row(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       // Text('PsicoAgendaAAAA', style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold)),
      //       Image.asset('assets/images/logo2.png', height: 150),
      //     ],
      //   ),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),

                _buildSummaryCards(
                  totalDay,
                  attendedDay,
                  missedDay,
                  pendingDay,
                ),
                const SizedBox(height: 20),

                // if (totalDay > 0) ...[
                //   SizedBox(
                //     height: 120,
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         SizedBox(
                //           width: 120,
                //           child: PieChart(
                //             PieChartData(
                //               sectionsSpace: 2,
                //               centerSpaceRadius: 25,
                //               sections: [
                //                 if (attendedDay > 0)
                //                   PieChartSectionData(color: const Color(0xFF315A68), value: attendedDay.toDouble(), title: '$attendedDay', radius: 30, titleStyle: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
                //                 if (missedDay > 0)
                //                   PieChartSectionData(color: const Color(0xFFE8BD8A), value: missedDay.toDouble(), title: '$missedDay', radius: 30, titleStyle: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
                //                 if (pendingDay > 0)
                //                   PieChartSectionData(color: Colors.black26, value: pendingDay.toDouble(), title: '$pendingDay', radius: 30, titleStyle: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)),
                //               ]
                //             )
                //           ),
                //         ),
                //         const SizedBox(width: 20),
                //         Column(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             _indicator(const Color(0xFF315A68), 'Asistencias'),
                //             const SizedBox(height: 4),
                //             _indicator(const Color(0xFFE8BD8A), 'Faltas'),
                //             const SizedBox(height: 4),
                //             _indicator(Colors.black26, 'Pendientes'),
                //           ],
                //         )
                //       ],
                //     ),
                //   ),
                //   const SizedBox(height: 20),
                // ],
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Colors.black54),
                      weekendStyle: TextStyle(color: Colors.black54),
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        color: darkTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                      formatButtonTextStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkTeal,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: darkTeal,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: darkTeal,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: darkTeal),
                      weekendTextStyle: TextStyle(
                        color: darkTeal.withOpacity(0.7),
                      ),
                      outsideTextStyle: TextStyle(
                        color: darkTeal.withOpacity(0.4),
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFFE8BD8A).withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8BD8A), width: 1.5),
                      ),
                      todayTextStyle: const TextStyle(
                        color: Color(0xFF1D3038),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  _isToday(_selectedDay) ? 'Citas para Hoy' : 'Citas del Día',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkTeal,
                  ),
                ),
                const SizedBox(height: 16),

                if (isAbsent)
                  GlassContainer(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.event_busy, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Día inhábil. Has marcado Inasistencia para todo este día.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'Eliminar Inasistencia',
                                  style: TextStyle(
                                    color: Color(0xFF1D3038),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: const Text(
                                  '¿Estás seguro de que deseas eliminar este evento? Se liberará el horario.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final ev = dayEvents.firstWhere(
                                        (e) => e.type == 'Inasistencia',
                                      );
                                      provider.deleteEvent(ev.id);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Inasistencia eliminada',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Eliminar',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                if (dayEvents.any((e) => e.type == 'Salida a campo'))
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dayEvents
                        .where((e) => e.type == 'Salida a campo')
                        .length,
                    itemBuilder: (context, index) {
                      final ev = dayEvents
                          .where((e) => e.type == 'Salida a campo')
                          .toList()[index];
                      final timeStr = DateFormat('h:mm a').format(ev.date);

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              timeStr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darkTeal,
                              ),
                            ),
                          ),
                          title: const Text(
                            'Salida a Campo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF315A68),
                            ),
                          ),
                          subtitle: Text(
                            ev.title ?? 'Sin lugar especificado',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.airport_shuttle, color: darkTeal),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Colors.white.withOpacity(
                                        0.9,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: const Text(
                                        'Eliminar Salida a Campo',
                                        style: TextStyle(
                                          color: Color(0xFF1D3038),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        '¿Estás seguro de que deseas eliminar este evento?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text(
                                            'Cancelar',
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            provider.deleteEvent(ev.id);
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Salida a campo eliminada',
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Eliminar',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                if (dayAppointments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'No hay citas en este día.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dayAppointments.length,
                    itemBuilder: (context, index) {
                      final appt = dayAppointments[index];
                      final patient = provider.getPatientById(appt.patientId);
                      final timeStr = DateFormat(
                        'h:mm a',
                      ).format(appt.scheduledDate);

                      Color statusColor;
                      switch (appt.status) {
                        case 'Llegó':
                          statusColor = const Color(
                            0xFF8DB09E,
                          ); // Pastel purple
                          break;
                        case 'No llegó':
                          statusColor = const Color(0xFFE8BD8A); // Pastel pink
                          break;
                        case 'Llegó con retardo':
                          statusColor = Colors.orangeAccent;
                          break;
                        case 'Programada':
                        default:
                          statusColor = Colors.black38;
                      }

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(width: 8, color: statusColor),
                                Expanded(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: darkTeal,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            patient?.name ??
                                                'Paciente desconocido',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: darkTeal,
                                            ),
                                          ),
                                        ),
                                        if (patient != null) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            patient.gender == 'Femenino'
                                                ? Icons.female
                                                : Icons.male,
                                            size: 18,
                                            color: patient.gender == 'Femenino'
                                                ? const Color(0xFFE8BD8A)
                                                : const Color(0xFF7A9BB8),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 10,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            appt.status,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Color(0xFFE8BD8A),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AppointmentDetailScreen(
                                                appointmentId: appt.id,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent, // Modal Glass
            builder: (ctx) => GlassContainer(
              margin: const EdgeInsets.all(16),
              borderRadius: 30.0,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '¿Qué deseas registrar?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkTeal,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF315A68),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        'Nueva Cita Clínica',
                        style: TextStyle(
                          color: darkTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Agendar paciente en consultorio',
                        style: TextStyle(color: Colors.black54),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppointmentFormScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8BD8A),
                        child: Icon(Icons.work_off, color: Colors.white),
                      ),
                      title: Text(
                        'Salida a Campo / Inasistencia',
                        style: TextStyle(
                          color: darkTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Bloquear horario del profesional',
                        style: TextStyle(color: Colors.black54),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EventFormScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  Widget _buildHeader(BuildContext context) {
    final todayStr = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());
    final user = AuthService().currentUser;
    final userName = (user?.displayName != null && user!.displayName!.isNotEmpty) 
        ? user.displayName! 
        : 'Psicóloga';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola\n$userName',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                  fontSize: 28,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                todayStr[0].toUpperCase() + todayStr.substring(1),
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (user?.photoURL != null)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF315A68).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage(user!.photoURL!),
              backgroundColor: Colors.transparent,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF315A68).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF315A68).withOpacity(0.1),
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 36, 
                  color: Color(0xFF315A68), 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCards(int total, int attended, int missed, int pending) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Total',
            total.toString(),
            Colors.blueAccent,
            Icons.list_alt,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            'Asist.',
            attended.toString(),
            const Color(0xFF315A68),
            Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            'Faltas',
            missed.toString(),
            const Color(0xFFE8BD8A),
            Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String count, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE8BD8A), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8BD8A).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: darkTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: darkTeal.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicator(Color color, String text) {
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: darkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
