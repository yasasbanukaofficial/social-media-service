import ballerina/io as _;
import ballerina/time;
import ballerina/http;

type User record {|
    readonly string userId;
    string name;
    int age;
    time:Date birthDate;
|};

type NewUser record {|
    string name;
    int age;
    time:Date birthDate;
|};

type ErrorMsg record {|
    string msg;
    string details;
    time:Utc timeStamp;
|};

type UserNotFound record {|
    *http:NotFound;
    ErrorMsg body;
|};

// Sample Data
table<User> key(userId) users = table [
    {
        userId: "1",
        name: "John Doe",
        age: 28,
        birthDate: {year: 1996, month: 5, day: 15}
    }
];

service / on new http:Listener(9090) {
    resource function get users() returns User[]|error {
        return users.toArray();
    }

    resource function get users/[int id] () returns User|UserNotFound|error {
        User? user = users[id.toString()];
        if user is () {
            UserNotFound userNotFound = {
                body: {msg: string `id: ${id}`, details: string `user/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }
        return user;
    }
}

