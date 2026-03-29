/**
 * 汎用ユーティリティ関数
 */

function greet(name) {
  return `Hello, ${name}!`;
}

function add(a, b) {
  return a + b;
}

function formatDate(date) {
  return date.toISOString().split('T')[0];
}

module.exports = { greet, add, formatDate };
