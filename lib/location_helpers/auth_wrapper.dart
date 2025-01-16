import 'location_request.dart';
import 'package:flutter_radar/flutter_radar.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.conntectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          Radar.setUserId(snapshot.data!.uid);
          Radar.setDescription("Logged in user");
          Radar.setMetadata({
            'email': snapshot.data!.email ?? 'unknown',
            'loggedIn' : true.toString(),
          });

          return const HomeScreen();
        } else {
          return LoginPage();
        }
      },
    );
  }
}