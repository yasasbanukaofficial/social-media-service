import ballerina/io as _;
import ballerina/time;
import ballerina/http;

type User record {|
    readonly int userId;
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
table<User> key(userId) userTable = table [
    {
        userId: 1,
        name: "John Doe",
        age: 28,
        birthDate: {year: 1996, month: 5, day: 15}
    }
];

service / on new http:Listener(9090) {
    resource function get users() returns User[]|error {
        return userTable.toArray();
    }

    resource function get users/[int id] () returns User|UserNotFound|error {
        User? user = userTable[id];
        if user is () {
            UserNotFound userNotFound = {
                body: {msg: string `id: ${id}`, details: string `user/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }
        return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error {
        // int userId;
        int userId = userTable.length() + 1; 
        while userTable[userId + 1] is User {
            userId += 1;
        }

        userTable.add({userId: userId, ...newUser});
        
        return http:CREATED;
    }

    resource function delete users/[int id]() returns http:NoContent|UserNotFound|error {
        User? existingUser = userTable[id];
        
        if existingUser is () {
            UserNotFound userNotFound = {
                body: {msg: string `id: ${id}`, details: string `user/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        _ = userTable.remove(id);
        return {};
    }

}

