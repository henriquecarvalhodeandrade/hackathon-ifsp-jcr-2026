import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _senhaVisivel = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      if (_isLogin) {
        await _auth.signIn(_emailController.text.trim(), _senhaController.text);
      } else {
        await _auth.signUp(_emailController.text.trim(), _senhaController.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('user-not-found') || msg.contains('wrong-password') || msg.contains('invalid-credential')) {
          msg = 'E-mail ou senha inválidos.';
        } else if (msg.contains('email-already-in-use')) {
          msg = 'Este e-mail já está cadastrado.';
        } else if (msg.contains('weak-password')) {
          msg = 'A senha deve ter pelo menos 6 caracteres.';
        } else {
          msg = 'Erro ao autenticar. Tente novamente.';
        }
        setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pegamos o bottom inset para não ficar atrás do teclado
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = ThemeController.of(context).isDark;

    // Theme-adaptive colors
    final accent = isDark ? const Color(0xFFDEFF9A) : const Color(0xFF4A7C1F);
    final cardBg = isDark
        ? const Color(0xFF1A1A1A).withOpacity(0.85)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.08);
    final titleColor = isDark ? Colors.white : const Color(0xFF212121);
    final subtitleColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF757575);
    final inputTextColor = isDark ? Colors.white : const Color(0xFF212121);
    final closeIconColor = isDark ? Colors.white54 : const Color(0xFF9E9E9E);
    final switchTextMuted = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF9E9E9E);
    final accentOnBtn = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.fromLTRB(28, 40, 28, 40 + bottomInset),
          constraints: const BoxConstraints(maxWidth: 400),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Material(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: borderColor),
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Botão fechar
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close, color: closeIconColor),
                            ),
                          ),

                          // Logo
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.location_city_rounded,
                                color: accentOnBtn,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Título
                          Text(
                            _isLogin ? 'Bem-vindo de volta' : 'Criar nova conta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin
                                ? 'Entre para reportar ocorrências'
                                : 'Junte-se ao JacaMap',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // E-mail
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: inputTextColor),
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Informe seu e-mail.';
                              if (!v.contains('@')) return 'E-mail inválido.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Senha
                          TextFormField(
                            controller: _senhaController,
                            obscureText: !_senhaVisivel,
                            style: TextStyle(color: inputTextColor),
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Informe sua senha.';
                              if (!_isLogin && v.length < 6) return 'Mínimo de 6 caracteres.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Mensagem de erro inline
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB71C1C).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFEF5350), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Botão entrar
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: accentOnBtn,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 3, color: accentOnBtn),
                                    )
                                  : Text(
                                      _isLogin ? 'ENTRAR' : 'CRIAR CONTA',
                                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Alternar
                          GestureDetector(
                            onTap: () => setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                              _formKey.currentState?.reset();
                            }),
                            child: Center(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: _isLogin ? 'Novo por aqui? ' : 'Já tem conta? ',
                                      style: TextStyle(color: switchTextMuted),
                                    ),
                                    TextSpan(
                                      text: _isLogin ? 'Cadastre-se' : 'Faça Login',
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
