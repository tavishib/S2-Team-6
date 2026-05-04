PreparedStatement ps = conn.prepareStatement(
    "UPDATE User SET is_banned = FALSE WHERE user_id = ?"
);