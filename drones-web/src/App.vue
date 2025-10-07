<!-- src/App.vue -->
<template>
  <div class="app">
    <RouterView />
  </div>
</template>

<script setup>
import { RouterView } from 'vue-router'
</script>

<style>
/* Estilos base muy mínimos para no interferir con tus vistas */
* { box-sizing: border-box; }
html, body, #app, .app { height: 100%; margin: 0; }
body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, sans-serif; }
</style>
