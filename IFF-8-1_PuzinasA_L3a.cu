// LAB1b.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <iostream>
#include <fstream>
#include <string>
#include <string.h>
#include <stdlib.h>

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
            while((pos = line.find(seperator)) != std::string::npos){
                std::string part = line.substr(0,pos);
                parsedItems[currChunk++] = part;
                line.erase(0, pos + 1);
            }
            parsedItems[2] = line.substr(0, line.find('\n'));
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

void copyItemsToArrays(Goods goods, char* names, int* namesLenght, int* nameChunkSize, int* amounts, float* prices){
    int curNamesPos = 0;
    int curChunk = 0;
    for( int i = 0; i < goods.size(); i++){
        Good curGood = goods.Array[i];
        amounts[i] = curGood.Amount;
        prices[i] = curGood.Price;

        int len = curGood.Name.length();
        namesLenght[i] = len;
        for(int j = 0; j < len; j++){ 
            names[curNamesPos++] = curGood.Name[j];
        }
        curChunk++;
        curNamesPos = curChunk * *nameChunkSize;
    }
}

void writeToFile(std::string fileName, char* results){
    std::ofstream stream(fileName);
    if(stream.is_open()){
        stream << results;
    }
    stream.close();
}

__global__ void proccesGoods(char* names, int* namesLenght, int* nameChunkSize, int* amounts, float* prices, int* arraySize, int* resultCount, char* results);
__device__ char* getName(char* names, int lenghtOfName, int index, int nameChunkSize);
__device__ char* getResult(char* name, int nameLenght, int amount, float price);
__device__ int fieldSum(int amount, float price);
__device__ char* addNumberToName(char* name, int nameLenght, int number);
__device__ void setSliceBoundaries(int* startIndex, int* endIndex, int arrSize);
__device__ void writeResult(char* results, char* result, int resultSize, int index, int maxResultSize);
__device__ bool isAceptable(char* data);
int main(){
    std::string resultFile ="IFF-8-1_PuzinasA_L3_rez.txt";
    //std::string dataFile = "IFF-8-1_PuzinasA_L1a_dat_1.txt";
    std::string dataFile = "IFF-8-1_PuzinasA_L1a_dat_2.txt";
    //std::string dataFile = "IFF-8-1_PuzinasA_L1a_dat_3.txt";
    int threadCount = 4;
    auto goods = readGoodsFromFile(dataFile, ";");
    int maxNameSize = maxSize(*goods) + 5;
    int sizeOfArray = goods->size();
    int resultCount = 0;

    size_t namesArrSize = sizeof(char) * maxNameSize * sizeOfArray;
    size_t namesLenghtArrSize = sizeof(int) * sizeOfArray;
    size_t amountsArrSize = sizeof(int) * sizeOfArray;
    size_t pricesArrSize = sizeof(float) * sizeOfArray;
    size_t resultArrSize = sizeof(char) * (maxNameSize + 5) * sizeOfArray;

    char* names = (char*)malloc(namesArrSize);
    int* namesLenght = (int*)malloc(namesLenghtArrSize);
    int* amounts = (int*)malloc(amountsArrSize);
    float* prices = (float*)malloc(pricesArrSize);    

    copyItemsToArrays(*goods, names, namesLenght, &maxNameSize, amounts, prices);  
      
    //Cuda name arrays
    char* cudaNames;
    int* cudaNamesLenght;
    int* cudaMaxNameSize;
    //Cuda number arrays
    int* cudaAmounts;
    float* cudaPrices;
    //Cuda array size
    int* cudaSizeOfArray;
    int* cudaResultCount;
    //Cuda result
    char* cudaResult;
    //Cuda memory allocation
    cudaMalloc(&cudaNames, namesArrSize);
    cudaMalloc(&cudaNamesLenght, namesLenghtArrSize);
    cudaMalloc(&cudaMaxNameSize, sizeof(int));
    
    cudaMalloc(&cudaAmounts, amountsArrSize);
    cudaMalloc(&cudaPrices, pricesArrSize);
    
    cudaMalloc(&cudaSizeOfArray, sizeof(int));
    cudaMalloc(&cudaResultCount, sizeof(int));

    cudaMalloc(&cudaResult, resultArrSize);
    //-------------------------------------
    //Cuda memory copy
    cudaMemcpy(cudaNames, names, namesArrSize, cudaMemcpyHostToDevice);
    cudaMemcpy(cudaNamesLenght, namesLenght, namesLenghtArrSize, cudaMemcpyHostToDevice);
    cudaMemcpy(cudaMaxNameSize, &maxNameSize, sizeof(int), cudaMemcpyHostToDevice);

    cudaMemcpy(cudaAmounts, amounts, amountsArrSize, cudaMemcpyHostToDevice);
    cudaMemcpy(cudaPrices, prices, pricesArrSize, cudaMemcpyHostToDevice);

    cudaMemcpy(cudaSizeOfArray, &sizeOfArray, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(cudaResultCount, &resultCount, sizeof(int), cudaMemcpyHostToDevice);
    //-----------------------------
    proccesGoods<<<1, threadCount>>>(
        cudaNames,
        cudaNamesLenght,
        cudaMaxNameSize,
        cudaAmounts,
        cudaPrices,
        cudaSizeOfArray,
        cudaResultCount,
        cudaResult
    );
    
    cudaDeviceSynchronize();

    char* results = (char*)malloc(resultArrSize);
    cudaMemcpy(results, cudaResult, resultArrSize, cudaMemcpyDeviceToHost);
    writeToFile(resultFile, results);

}

__global__ void proccesGoods(char* names, int* namesLenght, int* nameChunkSize, int* amounts, float* prices, int* arraySize, int* resultCount, char* results){
	int startIndex = 0;
	int endIndex = 0;
    setSliceBoundaries(&startIndex, &endIndex, *arraySize);
    for(int i = startIndex; i < endIndex; i++){
        char* name = getName(names, namesLenght[i], i, *nameChunkSize);
        char* result = getResult(name, namesLenght[i], amounts[i], prices[i]);
        if(isAceptable(result)){
            int index = atomicAdd(resultCount, namesLenght[i] + 6);
            writeResult(results, result, namesLenght[i] + 5, index, *nameChunkSize + 5);
        }
    }

}
__device__ bool isAceptable(char* data){
    if(data[0] < 69)
        return true;

    return false;
}

__device__ void writeResult(char* results, char* result, int resultSize, int index, int maxResultSize){
    for(int i = index, j = 0; j < resultSize; i++, j++){
        results[i] = result[j];
    }
    results[index + resultSize] = '\n';
}


__device__ char* getName(char* names, int lenghtOfName, int index, int nameChunkSize){
    int start = index * nameChunkSize;
    char* result = new char[lenghtOfName];
    for(int i = 0; i < lenghtOfName; i++){
        result[i] = names[i + start];
    }
    return result;
}

__device__ char* getResult(char* name, int nameLenght, int amount, float price){
    int sum = fieldSum(amount, price);
    return addNumberToName(name, nameLenght, sum);
}

__device__ int fieldSum(int amount, float price){
    return (int)(amount + (int)price);
}
__device__ char* addNumberToName(char* name, int nameLenght, int number){
    char* result = new char[nameLenght + 5];
    for(int i = 0; i < nameLenght; i++){
        result[i] = name[i];
    }


    int currIndex = nameLenght;
    result[currIndex++] = '-';
    result[currIndex++] = (number / 1000) + '0';
    number = number - (number / 1000) * 1000;
    result[currIndex++] = (number / 100) + '0';
    number = number - (number / 100) * 100;
    result[currIndex++] = (number / 10) + '0';
    number = number - (number / 10) * 10;
    result[currIndex] = (number % 10) + '0';    
    return result;
}

__device__ void setSliceBoundaries(int* startIndex, int* endIndex, int arrSize){
    int chunkSize = arrSize / blockDim.x;
    *startIndex = chunkSize * threadIdx.x;
	*endIndex = (threadIdx.x == blockDim.x - 1) ? arrSize : chunkSize * (threadIdx.x + 1);
}

