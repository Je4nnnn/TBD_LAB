package com.drones.service;

import com.drones.dto.LoginDtos.LoginRes;
import com.drones.repository.db.UserDao;
import com.drones.repository.security.JwtUtil;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@Service
public class AuthService {
    private final UserDao users;
    private final PasswordEncoder encoder;
    private final JwtUtil jwt;

    public AuthService(UserDao users, PasswordEncoder encoder, JwtUtil jwt) {
        this.users = users; this.encoder = encoder; this.jwt = jwt;
    }

    public LoginRes login(String email, String password) {
        var u = users.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        if (!encoder.matches(password, u.passwordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        }
        var token = jwt.generate(u.id().toString(), Map.of("rol", u.rol(), "email", u.email()));
        return new LoginRes(token, u.rol(), u.nombre());
    }
}
