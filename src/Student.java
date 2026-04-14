public class Student extends User {

    private String major;

    public Student() {}

    public Student(int userId, String name, String email, String passwordHash, String major) {
        super(userId, name, email, passwordHash);
        this.major = major;
    }

    public String getMajor()        { return major; }
    public void   setMajor(String major) { this.major = major; }
}
