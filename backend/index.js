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

// Cargar todas las categorías
const categories = {
  'Jugadores de Fútbol': soccerPlayers,
  'Cosas cotidianas': JSON.parse(fs.readFileSync('cosas_cotidianas.json')),
  'Videojuegos': JSON.parse(fs.readFileSync('videojuegos.json')),
  'Deportes': JSON.parse(fs.readFileSync('deportes.json')),
  'Vehículos': JSON.parse(fs.readFileSync('vehiculos.json')),
  'Películas y Series': JSON.parse(fs.readFileSync('peliculas_y_series.json')),
  'Personajes Históricos y de Ciencia': JSON.parse(fs.readFileSync('personajes.json')),
};
console.log(`✅ ${Object.keys(categories).length} categorías cargadas.`);


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
    // Añadimos el estado 'isReady' y la categoría por defecto al crear la sala
    rooms[roomCode] = {
      players: [{ id: socket.id, name: playerName, isReady: false }],
      category: 'Jugadores de Fútbol' // Categoría por defecto
    };
    console.log(`✅ Sala creada: ${roomCode} por ${playerName}`);
    socket.emit('roomCreated', roomCode);
    // Enviamos la categoría inicial al creador
    socket.emit('categoryUpdated', rooms[roomCode].category);
  });

  socket.on('joinRoom', ({ playerName, roomCode }) => {
    const upperCaseRoomCode = roomCode.toUpperCase();
    if (rooms[upperCaseRoomCode]) {
      const playerExists = rooms[upperCaseRoomCode].players.some(player => player.id === socket.id);
      if (!playerExists) {
        rooms[upperCaseRoomCode].players.push({ id: socket.id, name: playerName, isReady: false });
        socket.join(upperCaseRoomCode);
        console.log(`👍 ${playerName} se unió a la sala ${upperCaseRoomCode}`);
        socket.emit('joinSuccess', { roomCode: upperCaseRoomCode, players: rooms[upperCaseRoomCode].players });

        // Notificar al nuevo jugador de la categoría actual
        socket.emit('categoryUpdated', rooms[upperCaseRoomCode].category);

        socket.to(upperCaseRoomCode).emit('updatePlayers', rooms[upperCaseRoomCode].players);
      } else {
        console.log(`🤔 ${playerName} ya está en la sala ${upperCaseRoomCode}`);
        socket.emit('alreadyJoined', { roomCode: upperCaseRoomCode, players: rooms[upperCaseRoomCode].players });
      }
    } else {
      socket.emit('error', 'La sala no existe');
    }
  });

  // Evento para que el anfitrión seleccione una categoría
  socket.on('selectCategory', ({ roomCode, category }) => {
    const room = rooms[roomCode];
    // Solo el anfitrión puede cambiar la categoría
    if (room && room.players.length > 0 && room.players[0].id === socket.id) {
      if (categories[category]) {
        room.category = category;
        console.log(`- El anfitrión ${socket.id} cambió la categoría de la sala ${roomCode} a ${category}`);
        // Notificamos a todos en la sala sobre el cambio
        io.to(roomCode).emit('categoryUpdated', category);
      } else {
        socket.emit('error', 'Categoría no válida');
      }
    }
  });

  const startNewRound = (roomCode) => {
    const room = rooms[roomCode];
    if (!room) return;

    const players = room.players;
    const playerCount = players.length;
    let impostorCount = 1;

    // REGLA: 1 impostor hasta 5 jugadores, 2 para 6 o más.
    if (playerCount >= 6) {
      impostorCount = 2;
    }

    const shuffledPlayers = [...players].sort(() => 0.5 - Math.random());
    
    // Seleccionar item de la categoría correcta
    const currentCategory = room.category || 'Jugadores de Fútbol';
    const items = categories[currentCategory];
    const assignedItem = items[Math.floor(Math.random() * items.length)];

    for (let i = 0; i < playerCount; i++) {
      const player = shuffledPlayers[i];
      let assignedRole;

      if (i < impostorCount) {
        assignedRole = { "name": "IMPOSTOR" };
      } else {
        assignedRole = assignedItem;
      }
      
      // Enviamos el rol y la categoría a cada jugador
      io.to(player.id).emit('gameStarted', { role: assignedRole, category: currentCategory });
    }

    console.log(`🚀 ¡Juego iniciado en la sala ${roomCode} con categoría "${currentCategory}"!`);
  };

  socket.on('startGame', (roomCode) => {
    const room = rooms[roomCode];
    if (room && room.players.length > 0 && room.players[0].id === socket.id) {
      startNewRound(roomCode);
    }
  });

  socket.on('playAgain', (roomCode) => {
    const room = rooms[roomCode];
    if (!room) {
      console.log(`⚠️  ${socket.id} intentó reiniciar una sala inexistente: ${roomCode}`);
      return;
    }

    const isHost = room.players.length > 0 && room.players[0].id === socket.id;

    if (isHost) {
      const allReady = room.players.every(p => p.id === socket.id || p.isReady);
      if (!allReady) {
        socket.emit('error', 'No todos los jugadores están listos.');
        return;
      }

      console.log(`✅ El anfitrión ${socket.id} está reiniciando la sala ${roomCode}.`);

      // Usamos la función refactorizada
      startNewRound(roomCode);

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

  socket.on('playerUnready', (roomCode) => {
    const room = rooms[roomCode];
    if (room) {
      const player = room.players.find(p => p.id === socket.id);
      if (player && player.isReady) {
        player.isReady = false;
        console.log(`- ${player.name} ya no está listo en la sala ${roomCode}.`);
        io.to(roomCode).emit('updatePlayers', room.players);
      }
    }
  });

  socket.on('disbandRoom', (roomCode) => {
    const room = rooms[roomCode];
    if (room && room.players.length > 0 && room.players[0].id === socket.id) {
      console.log(`- El anfitrión ${socket.id} ha disuelto la sala ${roomCode}.`);
      // Notificamos a los demás jugadores que la sala fue disuelta
      socket.to(roomCode).emit('roomDisbanded');
      // Eliminamos la sala del servidor
      delete rooms[roomCode];
    }
  });
  
  // Lógica de leaveRoom (sin cambios)
  socket.on('leaveRoom', (roomCode) => {
    const room = rooms[roomCode];
    if (room) {
      const playerIndex = room.players.findIndex(player => player.id === socket.id);
      if (playerIndex !== -1) {
        // Si el anfitrión abandona, disolvemos la sala
        if (playerIndex === 0) {
          console.log(`- El anfitrión ${socket.id} ha abandonado la sala ${roomCode}. Disolviendo...`);
          socket.to(roomCode).emit('roomDisbanded');
          delete rooms[roomCode];
        } else {
          room.players.splice(playerIndex, 1);
          socket.leave(roomCode);
          console.log(`👋 Jugador ${socket.id} abandonó la sala ${roomCode}`);
          io.to(roomCode).emit('updatePlayers', room.players);
        }
      }
    }
  });

  // Lógica de disconnect (sin cambios2)
  socket.on('disconnect', () => {
    console.log(`🔌 Jugador desconectado: ${socket.id}`);
    for (const roomCode in rooms) {
      const room = rooms[roomCode];
      const playerIndex = room.players.findIndex(player => player.id === socket.id);

      if (playerIndex !== -1) {
        // Si el anfitrión se desconecta, disolvemos la sala
        if (playerIndex === 0) {
          console.log(`- El anfitrión ${socket.id} se ha desconectado de la sala ${roomCode}. Disolviendo...`);
          socket.to(roomCode).emit('roomDisbanded');
          delete rooms[roomCode];
          console.log(`🗑️ Sala ${roomCode} eliminada.`);
        } else {
          // Si es otro jugador, simplemente lo eliminamos
          room.players.splice(playerIndex, 1);
          console.log(`👋 Jugador ${socket.id} abandonó la sala ${roomCode} por desconexión.`);
          io.to(roomCode).emit('updatePlayers', room.players);
        }
        // Salimos del bucle una vez que encontramos y manejamos al jugador
        break;
      }
    }
  });
});

server.listen(PORT, () => {
  console.log(`🚀 Servidor escuchando en el puerto ${PORT}`);
});