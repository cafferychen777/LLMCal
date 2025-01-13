global.Application = {
  currentApplication: () => ({
    includeStandardAdditions: true,
    displayNotification: jest.fn()
  })
};

global.$ = {
  // ... 之前定义的 $ mock 对象
}; 