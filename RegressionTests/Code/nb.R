timestamp <- Sys.time()
library(caret)
library(plyr)
library(recipes)
library(dplyr)

model <- "nb"

## In case the package or one of its dependencies uses random numbers
## on startup so we'll pre-load the required libraries: 

for(i in getModelInfo(model)[[1]]$library)
  do.call("requireNamespace", list(package = i))

#########################################################################

set.seed(2)
training <- twoClassSim(50, linearVars = 2)
testing <- twoClassSim(500, linearVars = 2)
trainX <- training[, -ncol(training)]
trainY <- training$Class

rec_cls <- recipe(Class ~ ., data = training) %>%
  step_center(all_predictors()) %>%
  step_scale(all_predictors())

cctrl1 <- trainControl(method = "cv", number = 3, returnResamp = "all",
                       classProbs = TRUE, 
                       summaryFunction = twoClassSummary)
cctrl2 <- trainControl(method = "LOOCV",
                       classProbs = TRUE, summaryFunction = twoClassSummary)
cctrl3 <- trainControl(method = "none",
                       classProbs = TRUE, summaryFunction = twoClassSummary)

set.seed(849)
test_class_cv_model <- train(trainX, trainY, 
                             method = "nb", 
                             trControl = cctrl1,
                             metric = "ROC", 
                             preProc = c("center", "scale"))

set.seed(849)
test_class_cv_form <- train(Class ~ ., data = training, 
                            method = "nb", 
                            trControl = cctrl1,
                            metric = "ROC", 
                            preProc = c("center", "scale"))

test_class_pred <- predict(test_class_cv_model, testing[, -ncol(testing)])
test_class_prob <- predict(test_class_cv_model, testing[, -ncol(testing)], type = "prob")
test_class_pred_form <- predict(test_class_cv_form, testing[, -ncol(testing)])
test_class_prob_form <- predict(test_class_cv_form, testing[, -ncol(testing)], type = "prob")

set.seed(849)
test_class_loo_model <- train(trainX, trainY, 
                              method = "nb", 
                              trControl = cctrl2,
                              metric = "ROC", 
                              preProc = c("center", "scale"))

set.seed(849)
test_class_none_model <- train(trainX, trainY, 
                               method = "nb", 
                               trControl = cctrl3,
                               tuneGrid = test_class_cv_model$bestTune,
                               metric = "ROC", 
                               preProc = c("center", "scale"))

test_class_none_pred <- predict(test_class_none_model, testing[, -ncol(testing)])
test_class_none_prob <- predict(test_class_none_model, testing[, -ncol(testing)], type = "prob")

set.seed(849)
test_class_rec <- train(x = rec_cls,
                        data = training,
                        method = "nb", 
                        trControl = cctrl1,
                        metric = "ROC")


if(
  !isTRUE(
    all.equal(test_class_cv_model$results, 
              test_class_rec$results))
)
  stop("CV weights not giving the same results")

test_class_imp_rec <- varImp(test_class_rec)


test_class_pred_rec <- predict(test_class_rec, testing[, -ncol(testing)])
test_class_prob_rec <- predict(test_class_rec, testing[, -ncol(testing)], 
                               type = "prob")

test_levels <- levels(test_class_cv_model)
if(!all(levels(trainY) %in% test_levels))
  cat("wrong levels")

#########################################################################

test_class_predictors1 <- predictors(test_class_cv_model)

test_class_predictors2 <- predictors(test_class_cv_model$finalModel)

#########################################################################

tests <- grep("test_", ls(), fixed = TRUE, value = TRUE)

sInfo <- sessionInfo()
timestamp_end <- Sys.time()

save(list = c(tests, "sInfo", "timestamp", "timestamp_end"),
     file = file.path(getwd(), paste(model, ".RData", sep = "")))

q("no")


