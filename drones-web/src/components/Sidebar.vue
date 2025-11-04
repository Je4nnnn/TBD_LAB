<template>
  <aside class="sidebar">
    <div class="sidebar-header">
      <span class="sidebar-logo">D</span>
      <h2>Drone<span>.io</span></h2>
    </div>
    <nav class="sidebar-nav">
      <a @click="$emit('navigate', '/')" class="sidebar-link">
        <span class="icon">📊</span>
        <span>Dashboard</span>
      </a>
      <a @click="$emit('navigate', '/drones')" class="sidebar-link">
        <span class="icon">🛸</span>
        <span>Drones</span>
      </a>
      <a @click="$emit('navigate', '/misiones')" class="sidebar-link" :class="{ active: active === 'misiones' }">
        <span class="icon">🎯</span>
        <span>Misiones</span>
      </a>
      <a @click="$emit('navigate', '/reportes')" class="sidebar-link">
        <span class="icon">📈</span>
        <span>Reportes</span>
      </a>
    </nav>
    <div class="sidebar-footer">
      <button class="logout-btn" @click="$emit('logout')">
        <span>Cerrar sesión</span>
      </button>
    </div>
  </aside>
</template>

<script setup>
const props = defineProps({
  active: String // para marcar la vista activa
});
</script>

<style scoped>
/* ... Copia aquí los estilos del sidebar de las vistas ... */
.sidebar {
  width: 260px;
  background: #fff;
  border-right: 1px solid #e0e7ff;
  display: flex;
  flex-direction: column;
  position: fixed;
  height: 100vh;
  box-shadow: 2px 0 10px rgba(0,0,0,0.05);
  z-index: 10;
}
.sidebar-header {
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 10px;
  border-bottom: 1px solid #e0e7ff;
}
.sidebar-logo {
  width: 40px;
  height: 40px;
  background: #6366f1;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 20px;
  box-shadow: 0 2px 8px rgba(99,102,241,0.25);
}
.sidebar-header h2 {
  color: #4fe6e5;
  font-weight: 600;
  font-size: 1.5rem;
  margin: 0;
}
.sidebar-header h2 span {
  color: #6366f1;
}
.sidebar-nav {
  flex: 1;
  padding: 1.5rem 0;
}
.sidebar-link {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 1.5rem;
  color: #4b5563;
  text-decoration: none;
  font-weight: 500;
  transition: background 0.2s, color 0.2s;
  border-left: 3px solid transparent;
  margin-bottom: 4px;
  cursor: pointer;
}
.sidebar-link:hover {
  background: #eef2ff;
  color: #6366f1;
}
.sidebar-link.active {
  background: #eef2ff;
  color: #6366f1;
  border-left-color: #6366f1;
  font-weight: 600;
}
.sidebar-footer {
  padding: 1.5rem;
  border-top: 1px solid #e0e7ff;
}
.logout-btn {
  width: 100%;
  padding: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background: #f8fafc;
  color: #4b5563;
  border: 1px solid #e0e7ff;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s; 
}
.logout-btn:hover {
  background: #d32f2fe8;
  color: black;
}
</style>
