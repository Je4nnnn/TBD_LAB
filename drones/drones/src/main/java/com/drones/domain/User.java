package com.drones.domain;

import java.util.UUID;

public record User(UUID id, String nombre, String email, String passwordHash, String rol) {}
