import axios from 'axios'

const API_URL = 'http://localhost:8080/api' // Cambia según tu backend

export async function login(email, password) {
  const res = await axios.post(`${API_URL}/login`, { email, password })
  if (res.data.token) {
    localStorage.setItem('jwt', res.data.token)
  }
  return res.data
}

export async function register(nombre, email, password) {
  return axios.post(`${API_URL}/register`, { nombre, email, password })
}

export function logout() {
  localStorage.removeItem('jwt')
}

export function getToken() {
  return localStorage.getItem('jwt')
}