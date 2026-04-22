const { DataTypes } = require('sequelize');
const sequelize = require('../db');

const ChatHistory = sequelize.define('ChatHistory', {
    sessionId: { type: DataTypes.STRING, allowNull: false },
    userId: { type: DataTypes.INTEGER, allowNull: false },
    title: { type: DataTypes.STRING, defaultValue: 'New Chat' },
    messages: { type: DataTypes.TEXT('long'), allowNull: false }
});

module.exports = ChatHistory;
