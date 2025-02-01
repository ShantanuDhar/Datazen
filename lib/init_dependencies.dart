import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datazen/core/cubits/auth_user/auth_user_cubit.dart';
import 'package:datazen/core/network/check_internet_connection.dart';
import 'package:datazen/core/usecase/current_user.dart';
import 'package:datazen/features/auth/data/datasources/auth_remote_datasources.dart';
import 'package:datazen/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:datazen/features/auth/domain/repository/auth_repository.dart';
import 'package:datazen/features/auth/domain/usecases/get_firebase_auth.dart';
import 'package:datazen/features/auth/domain/usecases/google_login.dart';
import 'package:datazen/features/auth/domain/usecases/is_user_email_verified.dart';
import 'package:datazen/features/auth/domain/usecases/update_email_verification.dart';
import 'package:datazen/features/auth/domain/usecases/user_login.dart';
import 'package:datazen/features/auth/domain/usecases/user_signup.dart';
import 'package:datazen/features/auth/domain/usecases/verify_user_email.dart';
import 'package:datazen/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:logger/logger.dart';


final serviceLocator = GetIt.instance;
Future<void> initDependencies() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _initAuth();


  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final Logger logger = Logger();
  serviceLocator.registerSingleton<GoogleSignIn>(googleSignIn);
  serviceLocator.registerSingleton<FirebaseAuth>(firebaseAuth);
  serviceLocator.registerSingleton<FirebaseFirestore>(firebaseFirestore);
  serviceLocator.registerSingleton<Logger>(logger);
  serviceLocator.registerFactory(() => InternetConnection());
  serviceLocator.registerFactory<CheckInternetConnection>(
      () => CheckInternetConnectionImpl(
            serviceLocator(),
          ));
  serviceLocator.registerLazySingleton(() => AuthUserCubit());
}

class DefaultFirebaseOptions {
  static var currentPlatform;
}

void _initAuth() {
  serviceLocator
    ..registerFactory<AuthRemoteDataSources>(
      () => AuthRemoteDataSourcesImpl(
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
      ),
    )
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        serviceLocator(),
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserSignup(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserLogin(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GoogleLogin(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => CurrentUser(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => VerifyUserEmail(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => IsUserEmailVerified(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UpdateEmailVerification(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetFirebaseAuth(
        serviceLocator(),
      ),
    )
    ..registerFactory(() => AuthBloc(
      updateEmailVerification: serviceLocator(),
      logger: serviceLocator(),
          userSignup: serviceLocator(),
          userLogin: serviceLocator(),
          currentUser: serviceLocator(),
          authUserCubit: serviceLocator(),
          googleSignIn: serviceLocator(),
          verifyUserEmail: serviceLocator(),
          getFirebaseAuth: serviceLocator(),
          isUserEmailVerified: serviceLocator(),
        ));
}