import ballerina/io as _;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/time;
import ballerina/http;
import ballerina/sql;

type User record {|
    @sql:Column {
        name: "id"
    }
    readonly int userId;
    string name;
    int age;
    
    @sql:Column {
        name: "birth_date"
    }
    time:Date birthDate;
    
    @sql:Column {
        name: "mobile_number"
    }
    string mobileNumber;
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

final mysql:Client dbClient = check new (
    host = "localhost",
    port = 3307,
    user = "root",
    password = "root",
    database = "social_media_database"
);

service / on new http:Listener(9090) {
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = dbClient->query(`SELECT * FROM users`);
        return from var user in userStream select user;
    }

    resource function get users/[int id] () returns User|UserNotFound|error {
        User|sql:Error user = dbClient->queryRow(`SELECT * FROM users where userId = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {msg: string `User with the id ${id} not found`, details: string `user/${id}` , timeStamp: time:utcNow()}
            };
            return userNotFound;
        }
        return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error {
        sql:ExecutionResult rslt = check dbClient->execute(`
            INSERT INTO Users (name, age, birthDate) 
            VALUES (${newUser.name}, ${newUser.age}, ${newUser.birthDate});
        `);
        if rslt.affectedRowCount > 0 {
            return http:CREATED;
        } else {
            return error("User not created");
        }
    }

    // resource function delete users/[int id]() returns http:NoContent|UserNotFound|error {
    //     User? existingUser = userTable[id];
        
    //     if existingUser is () {
    //         UserNotFound userNotFound = {
    //             body: {msg: string `id: ${id}`, details: string `user/${id}`, timeStamp: time:utcNow()}
    //         };
    //         return userNotFound;
    //     }

    //     _ = userTable.remove(id);
    //     return http:NO_CONTENT;
    // }

}

