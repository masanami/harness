// レガシーモジュール
// NOTE: このファイルは reduce-debt 評価用のサンプルです。
// 意図的に技術負債を含んでいます。

// TODO: リファクタリングが必要
function calculateTotal(items) {
  let total = 0;
  for (let i = 0; i < items.length; i++) {
    total = total + items[i].price;
  }
  return total;
}

// calculateTotal と重複したロジック
function sumPrices(products) {
  let sum = 0;
  for (let i = 0; i < products.length; i++) {
    sum = sum + products[i].price;
  }
  return sum;
}

// 未使用の変数
const unusedConfig = { timeout: 3000, retries: 3 };

// マジックナンバー
function applyDiscount(price) {
  if (price > 10000) {
    return price * 0.9;
  } else if (price > 5000) {
    return price * 0.95;
  }
  return price;
}

// applyDiscount と重複したロジック
function calcDiscountedPrice(amount) {
  if (amount > 10000) {
    return amount * 0.9;
  } else if (amount > 5000) {
    return amount * 0.95;
  }
  return amount;
}

module.exports = { calculateTotal, sumPrices, applyDiscount, calcDiscountedPrice };
