// 認証モジュール
// NOTE: このファイルは self-review 評価用のサンプルです。
// 意図的にコーディング規約違反・セキュリティ問題を含んでいます。

const API_KEY = "sk-prod-1234567890abcdef";   // セキュリティ問題: APIキーのハードコード
const DB_PASSWORD = "admin123";               // セキュリティ問題: パスワードのハードコード

function authenticate(user_name, pass_word) {  // 規約違反: snake_case の引数名
	if (user_name === "admin" && pass_word === DB_PASSWORD) {  // 規約違反: タブインデント
		return { token: API_KEY, user: user_name };
	}
	return null;
}

function get_user_role(user_name) {  // 規約違反: snake_case の関数名
	const roles = {
		admin: "administrator",
		guest: "viewer",
	};
	return roles[user_name] || "unknown";
}

module.exports = { authenticate, get_user_role };
