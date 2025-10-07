const express = require('express');
const http = require('http');
const { Server } = require("socket.io");
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server);
const PORT = 3000;

// 2. Leemos la lista de jugadores desde el archivo JSON
const playersData = fs.readFileSync('players.json');
const soccerPlayers = JSON.parse(playersData);

console.log(`✅ ${soccerPlayers.length} futbolistas cargados.`);

let rooms = {};

// // ===== NUEVA LISTA DE FUTBOLISTAS =====
// // Puedes añadir todos los nombres que quieras aquí
// const soccerPlayers = [
//   "Messi", "Ronaldo", "Neymar", "Mbappé", "Haaland", "De Bruyne", 
//   "Modrić", "Salah", "Vinícius Jr.", "Lewandowski", "Benzema", "Courtois",
//   "Ronaldinho", "Zidane", "Maradona", "Pelé", "Kroos", "Di María"
// ];

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
    
    rooms[roomCode] = {
      players: [{ id: socket.id, name: playerName }],
    };

    console.log(`✅ Sala creada: ${roomCode} por ${playerName}`);
    socket.emit('roomCreated', roomCode);
  });

  socket.on('joinRoom', ({ playerName, roomCode }) => {
    const upperCaseRoomCode = roomCode.toUpperCase();
    if (rooms[upperCaseRoomCode]) {
      rooms[upperCaseRoomCode].players.push({ id: socket.id, name: playerName });
      socket.join(upperCaseRoomCode);
      
      console.log(`👍 ${playerName} se unió a la sala ${upperCaseRoomCode}`);
      
      socket.emit('joinSuccess', { roomCode: upperCaseRoomCode, players: rooms[upperCaseRoomCode].players });
      socket.to(upperCaseRoomCode).emit('updatePlayers', rooms[upperCaseRoomCode].players);

    } else {
      socket.emit('error', 'La sala no existe');
    }
  });

  // ===== LÓGICA DE 'STARTGAME' ACTUALIZADA =====
  socket.on('startGame', (roomCode) => {
    const room = rooms[roomCode];
    if (!room || room.players[0].id !== socket.id) return;

    const players = room.players;
    const playerCount = players.length;
    let impostorCount = 1;

    if (playerCount >= 8) {
      impostorCount = 2;
    } else if (playerCount >= 4) {
      impostorCount = 1;
    }
    
    // Barajamos jugadores y futbolistas para que sea aleatorio
    const shuffledPlayers = [...players].sort(() => 0.5 - Math.random());
    const shuffledSoccerPlayers = [...soccerPlayers].sort(() => 0.5 - Math.random());

    for (let i = 0; i < playerCount; i++) {
      const player = shuffledPlayers[i];
      let assignedRole;

      if (i < impostorCount) {
        assignedRole = 'IMPOSTOR';
      } else {
        // Asignamos un futbolista de la lista barajada
        assignedRole = shuffledSoccerPlayers.pop() || "Futbolista Genérico"; // || es por si te quedas sin nombres
      }
      
      // Enviamos el rol de forma privada a cada jugador
      io.to(player.id).emit('gameStarted', { role: assignedRole });
    }

    console.log(`🚀 ¡Juego iniciado en la sala ${roomCode}! Roles asignados.`);
  });
  
  // Lógica de leaveRoom y disconnect se quedan igual
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