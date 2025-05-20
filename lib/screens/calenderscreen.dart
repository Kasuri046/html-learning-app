import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../resources/helper_notifi.dart';
import 'progressprovider.dart';
import '../components/bottom_navigation.dart';
import 'notification.dart';

class CalendarScreen extends StatefulWidget {
  final String userName;
  const CalendarScreen({required this.userName, Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<DateTime?> _selectedDate = [DateTime.now()];
  TimeOfDay _selectedTime = TimeOfDay.now();

  void _navigateToCustomBottomNavigation() {
    print("DEBUG: Back button pressed, navigating to CustomBottomNavigation");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CustomBottomNavigation(userName: widget.userName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG: Building CalendarScreen, userName: ${widget.userName}");
    return Scaffold(
      backgroundColor: Color(0xff023047),
      appBar: AppBar(
        backgroundColor: Color(0xff023047),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _navigateToCustomBottomNavigation,
        ),
        title: Text(
          "Schedule",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 10),
            color: Color(0xff023047),
            child: Center(
              child: Text(
                "Manage your lessons efficiently",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CalendarDatePicker2(
                      config: CalendarDatePicker2Config(
                        selectedDayHighlightColor: Color(0xff023047),
                        selectedDayTextStyle: TextStyle(fontFamily: 'Poppins', color: Colors.white),
                        firstDayOfWeek: 1,
                        firstDate: DateTime.now(),
                        weekdayLabelTextStyle:
                        GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                        dayTextStyle: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                        controlsTextStyle: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                        centerAlignModePicker: true,
                      ),
                      value: _selectedDate,
                      onValueChanged: (dates) => setState(() {
                        _selectedDate = dates;
                        _adjustTimeIfPast();
                        print("DEBUG: Selected date changed: ${_selectedDate.first}");
                      }),
                    ),
                    const SizedBox(height: 20),
                    Consumer<ProgressProvider>(
                      builder: (context, progressProvider, child) {
                        double progressValue = progressProvider.globalTotal > 0
                            ? progressProvider.globalProgress / progressProvider.globalTotal
                            : 0.0;
                        print("DEBUG: CalendarScreen progress: ${(progressValue * 100).toStringAsFixed(1)}%");
                        return Card(
                          color: Colors.blue[50],
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Course Progress",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff023047),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progressValue.clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey.shade400,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(Color(0xff023047)),
                                    minHeight: 10,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Overall Progress: ${(progressValue * 100).toStringAsFixed(1)}%',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff023047),
                          shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _setReminder,
                        child: Text(
                          "Set Reminder",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _adjustTimeIfPast() {
    DateTime now = DateTime.now();
    DateTime selectedDateTime = DateTime(
      _selectedDate.first!.year,
      _selectedDate.first!.month,
      _selectedDate.first!.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (selectedDateTime.isBefore(now)) {
      setState(() {
        _selectedTime = TimeOfDay.now();
      });
      print("DEBUG: Adjusted time to now: ${_selectedTime.format(context)}");
    }
  }

  void _setReminder() {
    print("DEBUG: Opening reminder bottom sheet");
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Set Reminder",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff023047),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate.first!,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              textTheme: GoogleFonts.poppinsTextTheme(
                                Theme.of(context).textTheme,
                              ),
                              colorScheme: ColorScheme.light(
                                primary: Color(0xff023047), // Header and selected date
                                onPrimary: Colors.white, // Text on primary color
                                surface: Colors.white, // Background
                                onSurface: Colors.black, // Text and icons
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Color(0xff023047), // Button text color
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDate = [pickedDate];
                          _adjustTimeIfPast();
                        });
                        setModalState(() {});
                        print("DEBUG: Picked date: $pickedDate");
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color(0xff023047).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xff023047), width: 1),
                      ),
                      child: Text(
                        "Selected Date: ${_selectedDate.first!.toLocal().toString().split(' ')[0]}",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff023047)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              textTheme: GoogleFonts.poppinsTextTheme(
                                Theme.of(context).textTheme,
                              ),
                              colorScheme: ColorScheme.light(
                                primary: Color(0xff023047), // Selected time and buttons
                                onPrimary: Colors.white, // Text on primary color
                                surface: Colors.white, // Background
                                onSurface: Colors.black, // Text and icons
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Color(0xff023047), // Button text color
                                ),
                              ),
                            ),
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                              child: child!,
                            ),
                          );
                        },
                      );
                      if (pickedTime != null) {
                        DateTime now = DateTime.now();
                        DateTime selectedDateTime = DateTime(
                          _selectedDate.first!.year,
                          _selectedDate.first!.month,
                          _selectedDate.first!.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        if (selectedDateTime.isBefore(now)) {
                          pickedTime = TimeOfDay.now();
                          selectedDateTime = DateTime(
                            _selectedDate.first!.year,
                            _selectedDate.first!.month,
                            _selectedDate.first!.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        }
                        if (pickedTime.hour < _selectedTime.hour) {
                          setState(() {
                            _selectedDate = [
                              _selectedDate.first!.add(const Duration(days: 1))
                            ];
                          });
                        }
                        setState(() {
                          _selectedTime = pickedTime!;
                        });
                        setModalState(() {});
                        print("DEBUG: Picked time: ${pickedTime.format(context)}");
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color(0xff023047).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xff023047), width: 1),
                      ),
                      child: Text(
                        "Selected Time: ${_selectedTime.format(context)}",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff023047)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff023047),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        DateTime scheduledDate = DateTime(
                          _selectedDate.first!.year,
                          _selectedDate.first!.month,
                          _selectedDate.first!.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                        int uniqueId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                        String formattedTime = _selectedTime.format(context);
                        String title = 'HTML Lesson Reminder ⏰';
                        String body = 'Hey ${widget.userName}, your lesson is set for $formattedTime !';
                        await NotificationHelper.scheduleNotification(
                          id: uniqueId,
                          title: title,
                          body: body,
                          scheduledTime: scheduledDate,
                          userName: widget.userName,
                        );
                        print("DEBUG: Scheduled notification with ID $uniqueId for $scheduledDate");
                        final event = Event(
                          title: 'HTML Lesson Reminder ⏰',
                          description: 'Continue learning HTML at $formattedTime.',
                          location: 'Online',
                          startDate: scheduledDate,
                          endDate: scheduledDate.add(const Duration(hours: 1)),
                          iosParams: const IOSParams(reminder: Duration(minutes: 15)),
                        );
                        await Permission.calendar.request();
                        if (await Permission.calendar.isGranted) {
                          try {
                            await Add2Calendar.addEvent2Cal(event);
                            print("DEBUG: Event added to calendar");
                          } catch (e) {
                            print("DEBUG: Error adding event to calendar: $e");
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Calendar access denied. Please grant permission.")),
                          );
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationDisplayPage(userName: widget.userName)),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Confirm Reminder",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}