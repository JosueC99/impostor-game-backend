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
    // Evitar que un jugador en una sala cree otra
    for (const roomCode in rooms) {
      if (rooms[roomCode].players.some(player => player.id === socket.id)) {
        socket.emit('error', 'Ya estás en una sala, no puedes crear otra.');
        return;
      }
    }

    const roomCode = generateRoomCode();
    socket.join(roomCode);
    // Añadimos el estado 'isReady' al crear la sala
    rooms[roomCode] = { players: [{ id: socket.id, name: playerName, isReady: false }] };
    console.log(`✅ Sala creada: ${roomCode} por ${playerName}`);
    socket.emit('roomCreated', roomCode);
  });

  socket.on('joinRoom', ({ playerName, roomCode }) => {
    const upperCaseRoomCode = roomCode.toUpperCase();
    if (rooms[upperCaseRoomCode]) {
      const playerExists = rooms[upperCaseRoomCode].players.some(player => player.id === socket.id);
      if (!playerExists) {
        // Añadimos el estado 'isReady' al unirse
        rooms[upperCaseRoomCode].players.push({ id: socket.id, name: playerName, isReady: false });
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
    if (!room) {
      console.log(`⚠️  ${socket.id} intentó reiniciar una sala inexistente: ${roomCode}`);
      return;
    }

    // Comprobación robusta del anfitrión
    const isHost = room.players.length > 0 && room.players[0].id === socket.id;

    if (isHost) {
      // CORRECCIÓN: La comprobación debe ir aquí dentro
      const allReady = room.players.every(p => p.id === socket.id || p.isReady);
      if (!allReady) {
        socket.emit('error', 'No todos los jugadores están listos.');
        return;
      }

      console.log(`✅ El anfitrión ${socket.id} está reiniciando la sala ${roomCode}.`);

      // Reasignar roles y reiniciar el juego para todos en la sala.
      // Esta es la misma lógica que 'startGame'. Podríamos refactorizarla en una función.
      const players = room.players;
      const playerCount = players.length;
      let impostorCount = 1;
      if (playerCount >= 5) {
        impostorCount = 2;
      }

      const shuffledPlayers = [...players].sort(() => 0.5 - Math.random());
      const assignedSoccerPlayer = soccerPlayers[Math.floor(Math.random() * soccerPlayers.length)];

      for (let i = 0; i < playerCount; i++) {
        const player = shuffledPlayers[i];
        let assignedRole;
        if (i < impostorCount) {
          assignedRole = { "name": "IMPOSTOR" };
        } else {
          assignedRole = assignedSoccerPlayer;
        }
        io.to(player.id).emit('gameStarted', { role: assignedRole });
      }

      console.log(`🚀 ¡Nueva ronda iniciada en la sala ${roomCode}!`);

      // Reiniciamos el estado 'isReady' de todos los jugadores para la siguiente ronda
      room.players.forEach(p => p.isReady = false);
      io.to(roomCode).emit('updatePlayers', room.players);

    } else {
      console.log(`⚠️  ${socket.id} (no anfitrión) intentó reiniciar la sala ${roomCode}.`);
    }
  });

  socket.on('playerReady', (roomCode) => {
    const room = rooms[roomCode];
    if (room) {
      const player = room.players.find(p => p.id === socket.id);
      if (player) {
        player.isReady = true;
        console.log(`👍 ${player.name} está listo en la sala ${roomCode}.`);
        io.to(roomCode).emit('updatePlayers', room.players);
      }
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