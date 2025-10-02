package com.drones.controller;

import com.drones.dto.LoginDtos.LoginReq;
import com.drones.dto.LoginDtos.LoginRes;
import com.drones.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {
    private final AuthService auth;
    public AuthController(AuthService auth){ this.auth = auth; }

    @PostMapping("/login")
    public ResponseEntity<LoginRes> login(@RequestBody @Valid LoginReq req){
        return ResponseEntity.ok(auth.login(req.email(), req.password()));
    }
}
