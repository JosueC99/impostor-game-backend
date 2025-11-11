const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const fs = require('fs');
const cors = require('cors');

const app = express();
app.use(cors());
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Permite conexiones desde cualquier origen
    methods: ["GET", "POST"]
  }
});

const PORT = 3000;

const playersData = fs.readFileSync('players.json');
const soccerPlayers = JSON.parse(playersData);
console.log(`✅ ${soccerPlayers.length} futbolistas cargados.`);

let rooms = {};

const generateRoomCode = () => {
  let code = '';
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (let i = 0; i < 6; i++) {
    code += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return code;
};

io.on('connection', (socket) => {
  console.log(`🔌 Nuevo jugador conectado: ${socket.id}`);

  socket.on('createRoom', (playerName) => {
    const roomCode = generateRoomCode();
    socket.join(roomCode);
    rooms[roomCode] = { players: [{ id: socket.id, name: playerName }] };
    console.log(`✅ Sala creada: ${roomCode} por ${playerName}`);
    socket.emit('roomCreated', roomCode);
  });

  socket.on('joinRoom', ({ playerName, roomCode }) => {
    const upperCaseRoomCode = roomCode.toUpperCase();
    if (rooms[upperCaseRoomCode]) {
      const playerExists = rooms[upperCaseRoomCode].players.some(player => player.id === socket.id);
      if (!playerExists) {
        rooms[upperCaseRoomCode].players.push({ id: socket.id, name: playerName });
        socket.join(upperCaseRoomCode);
        console.log(`👍 ${playerName} se unió a la sala ${upperCaseRoomCode}`);
        socket.emit('joinSuccess', { roomCode: upperCaseRoomCode, players: rooms[upperCaseRoomCode].players });
        socket.to(upperCaseRoomCode).emit('updatePlayers', rooms[upperCaseRoomCode].players);
      } else {
        console.log(`🤔 ${playerName} ya está en la sala ${upperCaseRoomCode}`);
        // Opcional: podrías emitir un evento para notificar al cliente que ya está unido
        socket.emit('alreadyJoined', { roomCode: upperCaseRoomCode, players: rooms[upperCaseRoomCode].players });
      }
    } else {
      socket.emit('error', 'La sala no existe');
    }
  });

  // ===== LÓGICA DE 'STARTGAME' COMPLETAMENTE CORREGIDA =====
  socket.on('startGame', (roomCode) => {
    const room = rooms[roomCode];
    if (!room || room.players[0].id !== socket.id) return;

    const players = room.players;
    const playerCount = players.length;
    let impostorCount = 1;

    // 1. REGLA DE IMPOSTORES CORREGIDA
    // Si hay 5 o más jugadores, son 2 impostores. Si no, es 1.
    if (playerCount >= 5) {
      impostorCount = 2;
    }

    // 2. MEJOR MÉTODO PARA BARAJAR JUGADORES (MÁS ALEATORIO)
    const shuffledPlayers = [...players].sort(() => 0.5 - Math.random());
    
    // 3. ELEGIMOS UN SOLO FUTBOLISTA PARA TODOS LOS TRIPULANTES
    const assignedSoccerPlayer = soccerPlayers[Math.floor(Math.random() * soccerPlayers.length)];

    // 4. ASIGNAMOS ROLES SEGÚN LAS NUEVAS REGLAS
    for (let i = 0; i < playerCount; i++) {
      const player = shuffledPlayers[i];
      let assignedRole;

      if (i < impostorCount) {
        // Para ser consistentes, el impostor también es un objeto
        assignedRole = { "name": "IMPOSTOR" };
      } else {
        // Todos los demás reciben el MISMO futbolista
        assignedRole = assignedSoccerPlayer;
      }
      
      // Enviamos el rol de forma privada a cada jugador
      io.to(player.id).emit('gameStarted', { role: assignedRole });
    }

    console.log(`🚀 ¡Juego iniciado en la sala ${roomCode}! Roles asignados.`);
  });

  socket.on('playAgain', (roomCode) => {
    const room = rooms[roomCode];
    // Solo el anfitrión (el primer jugador) puede reiniciar el juego
    if (room && room.players[0].id === socket.id) {
      console.log(`🔄 El anfitrión ha solicitado jugar de nuevo en la sala ${roomCode}.`);
      // Reutilizamos la lógica de 'startGame' para reiniciar la partida
      io.to(roomCode).emit('restartGame'); // Notificamos a los clientes para que vuelvan al lobby
    }
  });
  
  // Lógica de leaveRoom (sin cambios)
  socket.on('leaveRoom', (roomCode) => {
    const room = rooms[roomCode];
    if (room) {
      const playerIndex = room.players.findIndex(player => player.id === socket.id);
      if (playerIndex !== -1) {
        room.players.splice(playerIndex, 1);
        socket.leave(roomCode);
        console.log(`👋 Jugador ${socket.id} abandonó la sala ${roomCode}`);
        if (room.players.length === 0) {
          delete rooms[roomCode];
          console.log(`🗑️ Sala vacía ${roomCode} eliminada.`);
        } else {
          io.to(roomCode).emit('updatePlayers', room.players);
        }
      }
    }
  });

  // Lógica de disconnect (sin cambios2)
  socket.on('disconnect', () => {
    console.log(`🔌 Jugador desconectado: ${socket.id}`);
    let roomCodeToUpdate = null;
    for (const roomCode in rooms) {
      const room = rooms[roomCode];
      const playerIndex = room.players.findIndex(player => player.id === socket.id);
      if (playerIndex !== -1) {
        room.players.splice(playerIndex, 1);
        roomCodeToUpdate = roomCode;
        break;
      }
    }
    if (roomCodeToUpdate) {
      if (rooms[roomCodeToUpdate].players.length === 0) {
        delete rooms[roomCodeToUpdate];
      } else {
        io.to(roomCodeToUpdate).emit('updatePlayers', rooms[roomCodeToUpdate].players);
      }
    }
  });
});

server.listen(PORT, () => {
  console.log(`🚀 Servidor escuchando en el puerto ${PORT}`);
});