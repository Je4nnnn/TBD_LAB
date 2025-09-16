package com.drones.api;

import com.drones.infra.db.MissionDao;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/misiones")
public class MissionController {
    private final MissionDao dao;
    public MissionController(MissionDao dao){ this.dao = dao; }

    // Crear misión (Pendiente)
    public record CrearReq(@NotBlank String tipo, String ruta_planeada){}
    public record CrearRes(UUID id){}
    @PostMapping
    public CrearRes crear(@RequestBody CrearReq req){
        UUID id = dao.crear(req.tipo(), req.ruta_planeada());
        return new CrearRes(id);
    }

    // Listar
    @GetMapping
    public List<Map<String,Object>> listar(){
        return dao.listar();
    }

    // Asignar misión a dron (llama al procedimiento almacenado)
    @PostMapping("/{misionId}/asignar/{dronId}")
    public void asignar(@PathVariable UUID misionId, @PathVariable UUID dronId){
        dao.asignar(misionId, dronId);
    }

    // Completar misión
    public record CompletarReq(Integer bateria_consumida_pct){}
    @PostMapping("/{misionId}/completar")
    public void completar(@PathVariable UUID misionId, @RequestBody(required = false) CompletarReq body){
        dao.completar(misionId, body!=null ? body.bateria_consumida_pct() : null);
    }

    // Fallar misión
    public record FallarReq(String motivo){}
    @PostMapping("/{misionId}/fallar")
    public void fallar(@PathVariable UUID misionId, @RequestBody(required = false) FallarReq body){
        dao.fallar(misionId, body!=null ? body.motivo() : null);
    }
}
