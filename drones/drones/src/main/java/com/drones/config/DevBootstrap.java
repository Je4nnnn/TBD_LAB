package com.drones.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DevBootstrap {

    @Bean
    CommandLineRunner forceDemoPasswords(JdbcTemplate jdbc, PasswordEncoder encoder) {
        return args -> {
            String adminHash = encoder.encode("admin123");
            String opHash    = encoder.encode("admin123");

            // Si existen, les reasigna el hash; si no existen, los crea.
            jdbc.update("""
                INSERT INTO drones_db.usuarios (nombre, email, password_hash, rol)
                VALUES ('Admin', 'admin@drones.local', ?, 'ADMIN')
                ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash
            """, adminHash);

            jdbc.update("""
                INSERT INTO drones_db.usuarios (nombre, email, password_hash, rol)
                VALUES ('Operador Uno', 'op1@drones.local', ?, 'OPERADOR')
                ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash
            """, opHash);

            System.out.println("[DEV] Credenciales listas: admin@drones.local / admin123  |  op1@drones.local / admin123");
        };
    }
}
