#include <sstream>
#include <iostream>
#include <fstream>
#include <openssl/sha.h>
#include <iomanip>

using namespace std;

SHA256_CTX sha256;
unsigned char my_hash[SHA256_DIGEST_LENGTH];

static const std::string base64_chars = 
"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
"abcdefghijklmnopqrstuvwxyz"
"0123456789+/";

string base64_encode(unsigned char const* bytes_to_encode, unsigned int in_len) {
  std::string ret;
  int i = 0;
  int j = 0;
  unsigned char char_array_3[3];
  unsigned char char_array_4[4];

  while (in_len--) {
    char_array_3[i++] = *(bytes_to_encode++);
    if (i == 3) {
      char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
      char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
      char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
      char_array_4[3] = char_array_3[2] & 0x3f;

      for(i = 0; (i <4) ; i++)
        ret += base64_chars[char_array_4[i]];
      i = 0;
    }
  }

  if (i)
  {
    for(j = i; j < 3; j++)
      char_array_3[j] = '\0';

    char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
    char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
    char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
    char_array_4[3] = char_array_3[2] & 0x3f;

    for (j = 0; (j < i + 1); j++)
      ret += base64_chars[char_array_4[j]];

    while((i++ < 3))
      ret += '=';

  }
  return ret;
}

int main(int argc, char **argv){
  if (argc<2) return -1;

  ifstream is;
  int BLOCK = 1024;
  streampos pos;

  is.open(argv[1], ios::in | ios::binary);
  SHA256_Init(&sha256);
  if (is) {
    is.seekg (0, is.end);
    int length = is.tellg();
    is.seekg (0, is.beg);

    char * buffer = new char [BLOCK];
    while(is){
      is.read(buffer, BLOCK);
      SHA256_Update(&sha256,buffer,is.gcount());
    }
    is.close();
    delete[] buffer;
  } else {
    cout << "Unable to open file";
    return 0;
  }
  SHA256_Final(my_hash, &sha256);
  cout << "sha2:" << base64_encode(my_hash, SHA256_DIGEST_LENGTH) << endl;
  return 0;
}
