<!-- src/App.vue -->
<script setup>
import { RouterView, useRoute } from 'vue-router';
import { computed } from 'vue';
import NavBar from './components/NavBar.vue';

const route = useRoute();
const showNav = computed(() => route.path !== '/login');
</script>

<template>
  <div>
    <NavBar v-if="showNav" />
    <RouterView />
  </div>
</template>
