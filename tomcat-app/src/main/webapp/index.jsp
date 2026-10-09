<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Rahul's Tomcat Application</title>
</head>
<body>
    <h1>Tomcat deployment successful!</h1>
    <p>This WAR was deployed through Jenkins.</p>
    <p>Server time: <%= java.time.Instant.now() %></p>
</body>
</html>