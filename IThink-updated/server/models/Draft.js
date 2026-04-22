const { DataTypes } = require('sequelize');
const sequelize = require('../db');
const User = require('./User');

const Draft = sequelize.define('Draft', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  title: { type: DataTypes.STRING, defaultValue: 'Untitled Document' },
  content: { type: DataTypes.TEXT, allowNull: false, defaultValue: '' },
  analysis: { type: DataTypes.TEXT, allowNull: true, defaultValue: null },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  deletedAt: { type: DataTypes.DATE, allowNull: true, defaultValue: null }
});

Draft.belongsTo(User, { foreignKey: 'userId' });

module.exports = Draft;
