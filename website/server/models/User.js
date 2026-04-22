const { DataTypes } = require('sequelize');
const sequelize = require('../db');

const User = sequelize.define('User', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  email: { type: DataTypes.STRING, allowNull: true, validate: { isEmail: true, len: [0, 255] } },
  password: { type: DataTypes.STRING(255), allowNull: true },
  googleId: { type: DataTypes.STRING(255), allowNull: true },
  displayName: { type: DataTypes.STRING(255) },
  bio: { type: DataTypes.TEXT, allowNull: true },
  institution: { type: DataTypes.STRING(255), allowNull: true },
  location: { type: DataTypes.STRING(255), allowNull: true },
  avatarUrl: { type: DataTypes.TEXT, allowNull: true },
  persona: { type: DataTypes.STRING(10), defaultValue: '1' },
  agreedToTerms: { type: DataTypes.BOOLEAN, defaultValue: false }
});

module.exports = User;