const bcrypt =require('bcrypt');
async function main() {
    const password ='123456';  
    const hashpassword=await bcrypt.hash(password,10);
    console.log(hashpassword);
}
main();