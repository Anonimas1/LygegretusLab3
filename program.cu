// LAB1b.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <iostream>
#include <fstream>
#include <string>

class Good{
public:
    std::string Name;
    int Amount;
    float Price;

    Good() {}

    Good(std::string parts[]){
        Name = parts[0];
        Amount = std::atoi(parts[1].c_str());
        Price = std::atoi(parts[2].c_str());
    }
    
    int sizeOfName(){
        return Name.size();
    }
};

class Goods{
public:
    Good Array[30];

    int size(){
        return sizeof(Array) / sizeof(Array[0]);
    }
};

Goods* readGoodsFromFile(std:: string fileName, std::string seperator){
    Goods* goods = new Goods();
    std::string line;
    std::ifstream stream(fileName);
    int currLine = 0;
    std::string parsedItems[3];
    if(stream.is_open()){
        while(std::getline(stream, line))
        {
            int currChunk = 0;
            int pos = 0;
            std::string part;
            while((pos = line.find(seperator)) != std::string::npos){
                part = line.substr(0,pos);
                parsedItems[currChunk++] = part;
                line.erase(0, pos + 1);
            }
            goods->Array[currLine++] = Good(parsedItems);
        }
        stream.close();
    }
    return goods;
}

int maxSize(Goods goods){
    int max = goods.Array[0].sizeOfName();
    for(int i = 1; i < goods.size(); i++){
        int temp = goods.Array[i].sizeOfName();
        if(temp > max)
            max = temp;
    }
    return max;
}

void copyItemsToArrays(Goods goods, char* names, int* namesLenght, int* amount, float* price){
    int curNamesPos = 0;
    for( int i = 0; i < goods.size(); i++){
        Good curGood = goods.Array[i];
        amount[i] = curGood.Amount;
        price[i] = curGood.Price;

        int len = std::string::strlen(curGood.Name);
        namesLenght[i] = len;
        for(int j = 0; i < len; j++){
            names[curNamesPos++] = curGood.Name[j];
        }
    }
}


int main(){
    int threadCount = 4;
    auto goods = readGoodsFromFile("IFF-8-1_PuzinasA_L1a_dat_1.txt", ";");
    int maxResultSize = maxSize(*goods) + 5;


    std::cout<<"HELLO";
}

