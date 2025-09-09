package com.drones.infra.db;

import com.drones.domain.User;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class UserDao {
    private final JdbcTemplate jdbc;
    public UserDao(JdbcTemplate jdbc){ this.jdbc = jdbc; }

    public Optional<User> findByEmail(String email){
        var list = jdbc.query("""
        SELECT id, nombre, email, password_hash, rol
        FROM drones_db.usuarios
        WHERE email = ?
        """,
                (rs, n) -> new User(
                        rs.getObject("id", UUID.class),
                        rs.getString("nombre"),
                        rs.getString("email"),
                        rs.getString("password_hash"),
                        rs.getString("rol")),
                email);
        return list.stream().findFirst();
    }
}
