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
    time:Date birthDate;
    string mobileNumber;
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

type DBConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

configurable DBConfig dbConfig = ?;

final mysql:Client dbClient = check new (...dbConfig);

service / on new http:Listener(9090) {
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = dbClient->query(`SELECT * FROM users`);
        return from var user in userStream select user;
    }

    resource function get users/[int id] () returns User|UserNotFound|error {
        User|sql:Error user = dbClient->queryRow(`SELECT * FROM users where id = ${id}`);
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
            INSERT INTO users (name, birth_Date, mobile_number) 
            VALUES (${newUser.name}, ${newUser.birthDate}, ${newUser.mobileNumber});
        `);
        if rslt.affectedRowCount > 0 {
            return http:CREATED;
        } else {
            return error("User not created");
        }
    }

    resource function delete users/[int id]() returns http:NoContent|UserNotFound|error {
        sql:ExecutionResult rslt = check dbClient->execute(`
            DELETE FROM users where id = ${id};
        `);

        if rslt.affectedRowCount > 0 {
            return http:NO_CONTENT;
        } else {
            return error("User not deleted");
        }
    }

}

