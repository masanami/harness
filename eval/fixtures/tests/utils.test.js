const { greet, add, formatDate } = require('../src/utils');

describe('greet', () => {
  test('名前を受け取り挨拶文を返す', () => {
    expect(greet('World')).toBe('Hello, World!');
  });

  test('空文字でも動作する', () => {
    expect(greet('')).toBe('Hello, !');
  });
});

describe('add', () => {
  test('2つの数値を加算する', () => {
    expect(add(1, 2)).toBe(3);
  });

  test('負の数も扱える', () => {
    expect(add(-1, 1)).toBe(0);
  });
});

describe('formatDate', () => {
  test('ISO形式の日付文字列を返す', () => {
    const date = new Date('2024-01-15T00:00:00.000Z');
    expect(formatDate(date)).toBe('2024-01-15');
  });
});
