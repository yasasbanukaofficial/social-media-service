import ballerina/http;
import ballerina/io as _;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/regex;

configurable DBConfig dbConfig = ?;

final mysql:Client socialMediaDB = check initSocialMediaDb();

function initSocialMediaDb() returns mysql:Client|error => check new (...dbConfig);

configurable http:RetryConfig retryConfig = {
    interval: 2,
    count: 3
};

// Circuit breaker means if a service is failing and if another services are to depend on it we implement a temp solution so it stops calling that service temporaly

http:Client sentimentEndpoint = check new("http://localhost:9099/text-processing", {
    timeout: 30, // After sending a request how much time should we wait until the request is cancelled as timeout
    retryConfig: {...retryConfig}
});

service /social\-media on new http:Listener(9090) {
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = socialMediaDB->query(`SELECT * FROM users`);
        return from var user in userStream
            select user;
    }

    resource function get users/[int id]() returns User|UserNotFound|error {
        User|sql:Error user = socialMediaDB->queryRow(`SELECT * FROM users where id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {msg: string `User with the id ${id} not found`, details: string `user/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }
        return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error {
        sql:ExecutionResult rslt = check socialMediaDB->execute(`
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
        sql:ExecutionResult rslt = check socialMediaDB->execute(`
            DELETE FROM users where id = ${id};
        `);

        if rslt.affectedRowCount > 0 {
            return http:NO_CONTENT;
        } else {
            return error("User not deleted");
        }
    }

    resource function get users/[int id]/posts() returns PostWithMeta[]|UserNotFound|error {
        User|sql:Error user = socialMediaDB->queryRow(`SELECT * FROM users where id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {msg: string `User with the id ${id} not found`, details: string `user/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        stream<Post, sql:Error?> postStream = check socialMediaDB->query(`SELECT * FROM posts WHERE user_id = ${id}`);
        Post[]| error posts = from var post in postStream select post;
        return mapToPostWithMeta(check posts);
    }

    resource function post users/[int id]/posts(NewPost newPost) returns http:Created|UserNotFound|PostForbidden|error {
        User|sql:Error user = check socialMediaDB->queryRow(`SELECT * FROM users where id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {msg: string `User with the id ${id} not found`, details: string `user/${id}`, timeStamp: time:utcNow()}
            };
            return userNotFound;
        }

        sql:ExecutionResult rslt = check socialMediaDB->execute(
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

function mapToPostWithMeta(Post[] post) returns PostWithMeta[] => from var postItem in post
    select {
        id: postItem.id, 
        description: postItem.description, 
        meta: {
            tags: regex:split(postItem.tags, ","), 
            category: postItem.category, 
            created_date: {
                year: postItem.created_date.year, 
                month: postItem.created_date.month, 
                day: postItem.created_date.day
            }
        }
    };
