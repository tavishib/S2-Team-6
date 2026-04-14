public class Administrator extends User {

    private int adminLevel;

    public Administrator() {}

    public Administrator(int userId, String name, String email, String passwordHash, int adminLevel) {
        super(userId, name, email, passwordHash);
        this.adminLevel = adminLevel;
    }

    public int  getAdminLevel()           { return adminLevel; }
    public void setAdminLevel(int level)  { this.adminLevel = level; }
}
