/// Bound to applicationId / bundle id below. Request a new key if you change the id.
library;


import 'dart:io' show Platform;


const androidApplicationId = 'com.identixia.facerecognitionsdk';


const iosBundleId = 'com.identixia.facerecognitionsdk.app';


const androidLicense =
    'pyyR2AEC9OOJtzGzuUiqnj1UoycDkCGbbI4QJOyk7/gwHGIAAAAOQ5Kyt/i1G3FerFj8/3i91gzLJCSx2P5IE+KM0uD7V8lSe57423nUFDc2YkS4siW+Nmt56Dpg+5s8l2kmjaUHzc7ArIMCPUTe7hTAG064A5aEjGsSNOLMSlm5A2njLclVM2YAMGQCMCzpL9yW4JYyQ+6LOq+3d+7/1DoQ4Q5N//A8XPN5yxNq30ZRxkInjsTvgHWjwKdkpAIwWImkTNEFVHBQsrZO4J8frcoHevTdrnzh1g22fL79wjwngeGNQsGaZkRO9E6p6Xhw';


const iosLicense =
    'pyyR2AEC7zN9Wyn4DBl07NPyfaywEidEJ5iCMkvLK4NNlWEAAAAKsSdB19zDzr1Vb0Joycs44e7Xoj1qDdD9jAxxAnUjTrtkMinvn6ocX55WUWLDe+oUOWLFfXwj/TmcgPrH6TqP06K52Il6WcH6tdYpdWKwhvwtSlhavSoYCWv/vQ1DwX+LZwAwZQIwLo5QslAL/4V5OmHqaTblNmOLnu+0dpiPpn6PJCPB7SNUuzTpO1gk46nJInIaqbSqAjEAs0lliuO0Ecgj+Op5hJkye7wU/QS16TC+7EgNjnq4ibKC/a7RlFYLFg+MLS1MJNyM';


String demoLicense() => Platform.isIOS ? iosLicense : androidLicense;
