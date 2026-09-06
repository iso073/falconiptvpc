import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/hive_bootstrap.dart';
import 'core/constants/hive_boxes.dart';
import 'core/device/form_factor.dart';
import 'features/profile/data/models/profile_model.dart';
import 'features/profile/data/repositories/profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FormFactor.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    fvp.registerWith();
  } else {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ProfileModelAdapter());
  }

  final Box<ProfileModel> profilesBox = await Hive.openBox<ProfileModel>(HiveBoxes.profiles);
  await HiveBootstrap.openAll();

  final ProfileRepository profileRepository = ProfileRepository(
    profilesBox: profilesBox,
    settingsBox: Hive.box<dynamic>(HiveBoxes.settings),
  );

  runApp(FalconIptvApp(profileRepository: profileRepository));
}
