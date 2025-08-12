part of 'auth_cubit.dart';

class AuthState extends Equatable {
  final User? user;
  final bool isLoading;
  final bool isLoggedIn;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    User? user,
    String? refreshToken,
    bool? isLoading,
    bool? isLoggedIn,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  @override
  List<Object?> get props => [user, isLoading, isLoggedIn];
}
