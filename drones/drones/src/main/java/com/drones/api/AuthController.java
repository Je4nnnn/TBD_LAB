package com.drones.api;

import com.drones.infra.db.UserDao;
import com.drones.infra.security.JwtUtil;
import jakarta.validation.constraints.NotBlank;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/auth")
@Validated
public class AuthController {

    private final UserDao users;
    private final PasswordEncoder encoder;
    private final JwtUtil jwt;

    public AuthController(UserDao users, PasswordEncoder encoder, JwtUtil jwt) {
        this.users = users; this.encoder = encoder; this.jwt = jwt;
    }

    public record LoginReq(@NotBlank String email, @NotBlank String password){}
    public record LoginRes(String token, String rol, String nombre){}

    @PostMapping("/login")
    public ResponseEntity<LoginRes> login(@RequestBody @Validated LoginReq req){
        var u = users.findByEmail(req.email())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        if (!encoder.matches(req.password(), u.passwordHash()))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
        var token = jwt.generate(u.id().toString(), Map.of("rol", u.rol(), "email", u.email()));
        return ResponseEntity.ok(new LoginRes(token, u.rol(), u.nombre()));
    }
}
