using System;
using System.Collections.Generic;
using System.Text;

namespace DSA
{
    public class SolutionWithOptimize
    {
        
            public int[] ProductExceptSelf(int[] nums)

            {
            // Time Complexity: O(n)
            // Space Complexity: O(1) (excluding the output array)

            int n = nums.Length;
                int[] result = new int[n];

                result[0] = 1;

                for (int i = 1; i < n; i++)
                {
                    result[i] = result[i - 1] * nums[i - 1];
                }
                int suffix = 1;
                for (int i = n - 1; i >= 0; i--)
                {
                    result[i] *= suffix;
                    suffix *= nums[i];

                }
                return result;


            }
        




    }
}
