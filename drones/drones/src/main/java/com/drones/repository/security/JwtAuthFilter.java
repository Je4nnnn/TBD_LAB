package com.drones.repository.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwt;

    public JwtAuthFilter(JwtUtil jwt) { this.jwt = jwt; }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        // 1) Preflight CORS: no tocar autenticación ni validar token
        if ("OPTIONS".equalsIgnoreCase(req.getMethod())) {
            chain.doFilter(req, res);
            return;
        }

        // 2) Autenticación por JWT (si viene el header)
        String hdr = req.getHeader(HttpHeaders.AUTHORIZATION);
        System.out.println("[JwtAuthFilter] " + req.getMethod() + " " + req.getRequestURI() + " - Header Authorization: " + (hdr != null ? "presente" : "ausente"));
        if (hdr != null && hdr.startsWith("Bearer ")) {
            String token = hdr.substring(7);
            try {
                var claims = jwt.parse(token).getBody();
                String userId = claims.getSubject();
                String rol = String.valueOf(claims.get("rol"));
                var auth = new UsernamePasswordAuthenticationToken(
                        userId, null, List.of(new SimpleGrantedAuthority("ROLE_" + rol)));
                SecurityContextHolder.getContext().setAuthentication(auth);
                System.out.println("[JwtAuthFilter] Autenticación exitosa para " + req.getMethod() + " " + req.getRequestURI() + " - Usuario: " + userId + ", Rol: " + rol);
            } catch (Exception e) {
                // token inválido -> seguimos sin autenticación
                System.err.println("[JwtAuthFilter] Error al parsear token para " + req.getMethod() + " " + req.getRequestURI() + ": " + e.getMessage());
                e.printStackTrace();
            }
        } else {
            // Log cuando no hay header de autorización
            System.err.println("[JwtAuthFilter] No se encontró header Authorization para " + req.getMethod() + " " + req.getRequestURI());
        }

        chain.doFilter(req, res);
    }
}
