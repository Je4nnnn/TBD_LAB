package com.drones.dto;

import jakarta.validation.constraints.NotBlank;

public final class LoginDtos {
    public record LoginReq(@NotBlank String email, @NotBlank String password) {}
    public record LoginRes(String token, String rol, String nombre) {}
    private LoginDtos() {}
}
