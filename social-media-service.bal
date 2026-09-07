import ballerina/io as _;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/time;
import ballerina/http;
import ballerina/sql;


configurable DBConfig dbConfig = ?;

final mysql:Client dbClient = check new (...dbConfig);

service /social\-media on new http:Listener(9090) {
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

    resource function get users/[int id]/posts() returns Post[]|UserNotFound|error {
        User|sql:Error user = dbClient->queryRow(`SELECT * FROM users where id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {msg: string `User with the id ${id} not found`, details: string `user/${id}` , timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        stream<Post, sql:Error?> postStream = check dbClient->query(`SELECT * FROM posts WHERE user_id = ${id}`);
        return from var post in postStream select post;
    }

    resource function post users/[int id]/posts(NewPost newPost) returns http:Created|UserNotFound|PostForbidden|error {
        User|sql:Error user = check dbClient->queryRow(`SELECT * FROM users where id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {msg: string `User with the id ${id} not found`, details: string `user/${id}` , timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        sql:ExecutionResult rslt = check dbClient->execute(
            `INSERT INTO posts (description, tags, category, user_id)
             VALUES (${newPost.description}, ${newPost.tags}, ${newPost.category}, ${id});`
        );

        if rslt.affectedRowCount > 0 {
            return http:CREATED;
        } else {
            return error("Error when adding new post");
        }
    }

}

